--!strict

-- Server module that manages giving, taking, and tracking player-owned fish.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Directory = require(ReplicatedStorage.Game.GameLibrary.Directory)
local FishTypes = require(ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Saving = require(ServerScriptService.Library.Saving)
local Functions = require(ReplicatedStorage.Library.Functions)

local Fish = {}

-- {[UserId]: {[UID]: Tool}}
local playerFishTools: {[number]: {[string]: Tool}} = {}

local function ensureBackpack(player: Player): Backpack?
    local backpack = player:FindFirstChildOfClass("Backpack")
    return backpack
end

local function getSchema(fishId: string): FishTypes.dir_schema?
    return Directory.Fish[fishId] or nil
end

local function createFishData(player: Player, params: FishTypes.create_params): FishTypes.data_schema
    local now = workspace:GetServerTimeNow()
    local uid = Functions.GenerateUID()
    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = params.FishId,
        Type = params.Type,
        Shiny = params.Shiny,
        Level = params.Level or 1,
        CreateTime = now,
        BaseTime = now,
    }
    return fishData
end

local function addToInventory(player: Player, fishData: FishTypes.data_schema)
    local save = Saving.Get(player)
    if not save then return end
    local inv = save.Inventory :: {FishTypes.data_schema}
    table.insert(inv, fishData)
end

local function removeFromInventory(player: Player, uid: string)
    local save = Saving.Get(player)
    if not save then return end
    local inv = save.Inventory :: {FishTypes.data_schema}
    for i = #inv, 1, -1 do
        if inv[i].UID == uid then
            table.remove(inv, i)
            break
        end
    end
end

function Fish.Give(player: Player, params: FishTypes.create_params): FishTypes.data_schema?
    local schema = getSchema(params.FishId)
    if not schema then
        warn("[Fish] Invalid FishId:", params.FishId)
        return nil
    end

    local backpack = ensureBackpack(player)
    if not backpack then
        warn("[Fish] No backpack for", player.Name)
        return nil
    end

    local toolTemplate = schema._script:FindFirstChild("Tool")
    if not toolTemplate or not toolTemplate:IsA("Tool") then
        warn("[Fish] No Tool template for", schema._id)
        return nil
    end

    local fishData = createFishData(player, params)
    addToInventory(player, fishData)

    local tool = toolTemplate:Clone()
    tool.Name = fishData.UID
    tool.Parent = backpack

    local userTools = playerFishTools[player.UserId]
    if not userTools then
        userTools = {}
        playerFishTools[player.UserId] = userTools
    end
    userTools[fishData.UID] = tool

    return fishData
end

function Fish.Take(player: Player, uid: string)
    local userTools = playerFishTools[player.UserId]
    if userTools then
        local tool = userTools[uid]
        if tool then
            tool:Destroy()
            userTools[uid] = nil
        end
    end
    removeFromInventory(player, uid)
end

local function populateToolsFromInventory(player: Player)
    local save = Saving.Get(player)
    if not save then return end
    local backpack = ensureBackpack(player)
    if not backpack then return end

    local inv = save.Inventory :: {FishTypes.data_schema}
    playerFishTools[player.UserId] = playerFishTools[player.UserId] or {}
    for _, fishData in ipairs(inv) do
        local schema = getSchema(fishData.FishId)
        if schema then
            local toolTemplate = schema._script:FindFirstChild("Tool")
            if toolTemplate and toolTemplate:IsA("Tool") then
                if not backpack:FindFirstChild(fishData.UID) then
                    local newTool = toolTemplate:Clone()
                    newTool.Name = fishData.UID
                    newTool.Parent = backpack
                    playerFishTools[player.UserId][fishData.UID] = newTool
                end
            end
        end
    end
end

local function onPlayerAdded(player: Player)
    playerFishTools[player.UserId] = playerFishTools[player.UserId] or {}

    if player.Character then
        task.defer(populateToolsFromInventory, player)
    end
    player.CharacterAdded:Connect(function()
        task.defer(populateToolsFromInventory, player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Saving.SaveAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    playerFishTools[player.UserId] = nil
end)

return Fish
