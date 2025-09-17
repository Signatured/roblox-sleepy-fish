--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Save = require(ReplicatedStorage.Library.Client.Save)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local Functions = require(ReplicatedStorage.Library.Functions)

local module = {}

local currentTool: Tool? = nil
local trackingStarted = false
local activeHighlightCleanup: (() -> ())? = nil

local function onToolAddedToCharacter(tool: Tool)
    currentTool = tool
    -- Clean previous highlight
    if activeHighlightCleanup then
        activeHighlightCleanup()
        activeHighlightCleanup = nil
    end

    -- Attach highlight based on tool Type attribute
    local toolType = tool:GetAttribute("Type")
    local toolMutation = tool:GetAttribute("Mutation")
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local function attachAndAnimate(hlTemplateName: string, mode: string)
        if not assets then return end
        local template = assets:FindFirstChild(hlTemplateName)
        if not template or not template:IsA("Highlight") then return end
        local highlight = template:Clone()
        highlight.Parent = tool

        if mode == "Gold" then
            -- 0.7 <-> 0.5 over 2s (match FishAnimations tweak)
            local cancel = Functions.RenderStepped(function()
                if not highlight or not highlight.Parent then return end
                local now = os.clock()
                local mid, amp, T = 0.7, 0.1, 2
                highlight.FillTransparency = math.clamp(mid + amp * math.sin(2 * math.pi * (now / T)), 0, 1)
            end, nil, false, true, Enum.RenderPriority.Last.Value)
            activeHighlightCleanup = function()
                if cancel and cancel.IsConnected and cancel:IsConnected() then cancel:Disconnect() end
                if highlight then highlight:Destroy() end
            end
        elseif mode == "Rainbow" then
            local cancelFn = Functions.Rainbow(highlight, "FillColor", 0.2) -- 5s per cycle ≈ 0.2 cps
            activeHighlightCleanup = function()
                if cancelFn then cancelFn() end
                if highlight then highlight:Destroy() end
            end
        elseif mode == "Shiny" then
            local cancel = Functions.RenderStepped(function()
                if not highlight or not highlight.Parent then return end
                local now = os.clock()
                local mid, amp, T = 0.7, 0.1, 2
                highlight.FillTransparency = math.clamp(mid + amp * math.sin(2 * math.pi * (now / T)), 0, 1)
            end, nil, false, true, Enum.RenderPriority.Last.Value)
            activeHighlightCleanup = function()
                if cancel and cancel.IsConnected and cancel:IsConnected() then cancel:Disconnect() end
                if highlight then highlight:Destroy() end
            end
        end
    end

    task.defer(function()
        -- Ensure tool is still current and valid when deferred runs
        if currentTool ~= tool then return end
        if not tool or not tool.Parent then return end
        if toolType == "Gold" then
            attachAndAnimate("GoldHighlight", "Gold")
        elseif toolType == "Rainbow" then
            attachAndAnimate("RainbowHighlight", "Rainbow")
        elseif toolType == "Shiny" then
            attachAndAnimate("ShinyHighlight", "Shiny")
        end

        if toolMutation == "Bloodfish" then
            FishTypes.MakeBloodfishModel(tool)
        end
    end)
    tool.Unequipped:Connect(function()
        if currentTool == tool then
            currentTool = nil
            if activeHighlightCleanup then
                activeHighlightCleanup()
                activeHighlightCleanup = nil
            end
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

function module.GetCurrentSpeedModifier(): number
    local carryingId = Players.LocalPlayer:GetAttribute("CarryingFishId")
    if not carryingId then return 1 end
    local dir = Directory.Fish[carryingId]
    return dir.Rarity.SpeedModifier or 1
end

startTracking()

return module