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

local function applyHighlightForTool(tool: Tool)
    -- Clean previous
    if activeHighlightCleanup then
        activeHighlightCleanup()
        activeHighlightCleanup = nil
    end

    local toolType = tool:GetAttribute("Type")
    if toolType ~= "Gold" and toolType ~= "Rainbow" and toolType ~= "Shiny" then
        return
    end

    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if not assets then return end

    local templateName = if toolType == "Gold" then "GoldHighlight" elseif toolType == "Rainbow" then "RainbowHighlight" else "ShinyHighlight"
    local template = assets:FindFirstChild(templateName)
    if not template or not template:IsA("Highlight") then return end

    -- Remove any previous highlights
    for _, child in ipairs(tool:GetChildren()) do
        if child:IsA("Highlight") and (child.Name == "EquippedHighlight" or child.Name == "Highlight") then
            child:Destroy()
        end
    end

    local highlight = template:Clone()
    highlight.Name = "EquippedHighlight"
    local adornee: Instance? = tool:FindFirstChild("Handle")
    if not adornee then adornee = tool:FindFirstChildWhichIsA("BasePart", true) end
    if adornee and adornee:IsA("BasePart") then
        highlight.Adornee = adornee
    end
    highlight.Parent = tool

    if toolType == "Rainbow" then
        local cancelFn = Functions.Rainbow(highlight, "FillColor", 0.2)
        activeHighlightCleanup = function()
            if cancelFn then cancelFn() end
            if highlight then highlight:Destroy() end
        end
    else
        local step = Functions.RenderStepped(function()
            if not highlight or not highlight.Parent then return end
            local now = os.clock()
            local mid, amp, T = 0.7, 0.1, 2
            highlight.FillTransparency = math.clamp(mid + amp * math.sin(2 * math.pi * (now / T)), 0, 1)
        end, nil, false, true, Enum.RenderPriority.Last.Value)
        activeHighlightCleanup = function()
            if step and step.IsConnected and step:IsConnected() then step:Disconnect() end
            if highlight then highlight:Destroy() end
        end
    end
end

local function onToolAddedToCharacter(tool: Tool)
    currentTool = tool
    -- Apply immediately and also after a short delay to catch late attributes
    applyHighlightForTool(tool)
    task.delay(0.05, function()
        if currentTool == tool then
            applyHighlightForTool(tool)
        end
    end)

    -- Also re-apply on Equipped event (handles cases where tool stays in character)
    tool.Equipped:Connect(function()
        if currentTool ~= tool then
            currentTool = tool
        end
        applyHighlightForTool(tool)
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
    tool.AncestryChanged:Connect(function()
        local char = Players.LocalPlayer.Character
        local inChar = char and tool.Parent and tool.Parent:IsDescendantOf(char)
        if currentTool == tool and (tool.Parent == nil or not inChar) then
            currentTool = nil
            if activeHighlightCleanup then
                activeHighlightCleanup()
                activeHighlightCleanup = nil
            end
        end
    end)

    -- Reapply highlight if Type changes while equipped
    tool:GetAttributeChangedSignal("Type"):Connect(function()
        if currentTool ~= tool then return end
        applyHighlightForTool(tool)
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

task.spawn(function()
    startTracking()
end)

return module