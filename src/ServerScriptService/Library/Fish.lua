--!strict

-- Server module that manages giving, taking, and tracking player-owned fish.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Saving = require(ServerScriptService.Library.Saving)
local Functions = require(ReplicatedStorage.Library.Functions)

local Fish = {}

-- {[UserId]: {[UID]: Tool}}
local playerFishTools: {[number]: {[string]: Tool}} = {}

local function ensureBackpack(player: Player): Backpack?
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        while player.Parent ~= nil and not backpack do
            task.wait(0.1)
            backpack = player:FindFirstChildOfClass("Backpack")
        end
    end
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
        Mutation = params.Mutation,
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

function Fish.GetFromInventory(player: Player, uid: string): FishTypes.data_schema?
    local save = Saving.Get(player)
    if not save then
        return nil
    end
    local inv = save.Inventory :: {FishTypes.data_schema}
    for _, entry in ipairs(inv) do
        if entry.UID == uid then
            return entry
        end
    end
    return nil
end

function Fish.ForceHoldFish(player: Player, fishData: FishTypes.data_schema)
	if not player or not fishData or typeof(fishData.UID) ~= "string" then
		return false
	end

	local save = Saving.Get(player)
	if not save then return false end

	-- Verify the fish exists in the player's inventory
	local hasFish = false
	for _, entry in ipairs(save.Inventory :: {FishTypes.data_schema}) do
		if entry.UID == fishData.UID then
			hasFish = true
			break
		end
	end
	if not hasFish then return false end

	local humanoid: Humanoid? = nil
	local character = player.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	if not humanoid then return false end

	-- Find the tool representing this fish (by UID) in character or backpack
	local tool: Tool? = nil
	local userTools = playerFishTools[player.UserId]
	if userTools then
		tool = userTools[fishData.UID]
	end
	if not tool then
		local backpack = ensureBackpack(player)
		local function findIn(container: Instance): Tool?
			for _, inst in ipairs(container:GetChildren()) do
				if inst:IsA("Tool") and inst:GetAttribute("UID") == fishData.UID then
					return inst
				end
			end
			return nil
		end
		if character then
			tool = findIn(character)
		end
		if not tool and backpack then
			tool = findIn(backpack)
		end
	end
	if not tool then return false end

	-- Equip the tool to force the player to hold it
	pcall(function()
		humanoid:EquipTool(tool :: Tool)
	end)
	return true
end

function Fish.Give(player: Player, params: FishTypes.create_params | FishTypes.swimming_fish_schema): FishTypes.data_schema?
    local asAny = params :: any
    local useExistingData: FishTypes.data_schema? = (asAny and asAny.FishData) and (asAny.FishData :: FishTypes.data_schema) or nil
    local fishId = if useExistingData then useExistingData.FishId else (params :: FishTypes.create_params).FishId
    local schema = getSchema(fishId)
    if not schema then
        warn("[Fish] Invalid FishId:", fishId)
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

    local fishData: FishTypes.data_schema
    if useExistingData then
        fishData = useExistingData
    else
        fishData = createFishData(player, params :: FishTypes.create_params)
    end
    addToInventory(player, fishData)

    local icon = schema.Icon
    if schema.MutationIcons and fishData.Mutation then
        icon = schema.MutationIcons[fishData.Mutation] or schema.Icon
    end

    local tool = toolTemplate:Clone()
    tool.Name = schema.DisplayName
    tool.TextureId = icon
    tool.ToolTip = `Level {fishData.Level}`
    tool:SetAttribute("UID", fishData.UID)
    tool:SetAttribute("Type", fishData.Type)
    tool:SetAttribute("Mutation", fishData.Mutation)
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
                    local icon = schema.Icon
                    if schema.MutationIcons and fishData.Mutation then
                        icon = schema.MutationIcons[fishData.Mutation] or schema.Icon
                    end

                    local newTool = toolTemplate:Clone()
                    newTool.Name = schema.DisplayName
                    newTool.TextureId = icon
                    newTool.ToolTip = `Level {fishData.Level}`
                    newTool:SetAttribute("UID", fishData.UID)
                    newTool:SetAttribute("Type", fishData.Type)
                    newTool:SetAttribute("Mutation", fishData.Mutation)
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
        task.delay(0.1, populateToolsFromInventory, player)
    end
    player.CharacterAdded:Connect(function()
        task.delay(0.1, populateToolsFromInventory, player)
    end)
end

-- for _, player in ipairs(Players:GetPlayers()) do
--     onPlayerAdded(player)
-- end
Saving.SaveAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    playerFishTools[player.UserId] = nil
end)

return Fish
