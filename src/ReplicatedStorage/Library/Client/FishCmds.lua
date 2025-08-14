--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Save = require(ReplicatedStorage.Library.Client.Save)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)

local module = {}

local currentTool: Tool? = nil
local trackingStarted = false

local function onToolAddedToCharacter(tool: Tool)
    currentTool = tool
    tool.Unequipped:Connect(function()
        if currentTool == tool then
            currentTool = nil
        end
    end)
    tool.AncestryChanged:Connect(function()
        if currentTool == tool and (tool.Parent == nil or not tool.Parent:IsDescendantOf(Players.LocalPlayer.Character or tool)) then
            currentTool = nil
        end
    end)
end

local function startTracking()
    if trackingStarted then return end
    trackingStarted = true
    local player = Players.LocalPlayer
    local function hookCharacter(character: Model)
        -- pick up any pre-equipped tool
        local existing = character:FindFirstChildOfClass("Tool")
        if existing then
            onToolAddedToCharacter(existing)
        end
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                onToolAddedToCharacter(child)
            end
        end)
        character.ChildRemoved:Connect(function(child)
            if child == currentTool then
                currentTool = nil
            end
        end)
    end

    if player.Character then
        hookCharacter(player.Character)
    end
    player.CharacterAdded:Connect(hookCharacter)
end

function module.GetCurrentFishData(): FishTypes.data_schema?
    startTracking()
    local tool = currentTool
    if not tool then return nil end
    local uid = tool:GetAttribute("UID")
    if type(uid) ~= "string" or uid == "" then
        return nil
    end
    local save = Save.Get()
    if not save then return nil end
    local inv = save.Inventory :: {FishTypes.data_schema}
    for _, entry in ipairs(inv) do
        if entry.UID == uid then
            return entry
        end
    end
    return nil
end

return module