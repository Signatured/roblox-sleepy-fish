--!strict

local Players = game:GetService("Players")

local Functions = require(game.ReplicatedStorage.Library.Functions)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local proximityPrompts = playerGui:WaitForChild("ProximityPrompts", 99999999)

local whitelistedAddornees = {
    ["SellAttachment"] = true,
    ["PickupAttachment"] = true,
    ["StealAttachment"] = true,
    ["ExclusiveAttachment"] = true,
}

local prompts: { [BillboardGui]: boolean } = {}

local function enforceTransparent(frame: Frame)
    local function apply()
        if frame.BackgroundTransparency ~= 1 then
            frame.BackgroundTransparency = 1
        end
    end
    apply()
    frame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(apply)
end

local function setupPrompt(prompt: BillboardGui)
    local addornee = prompt.Adornee
    if not addornee or not whitelistedAddornees[addornee.Name] then
        return
    end

    prompt.ChildRemoved:Connect(function(child)
        print(child.Name)
    end)

    if prompts[prompt] then
        return
    end

    local frame = prompt:FindFirstChild("Frame")::Frame
    if not frame then
        return
    end

    enforceTransparent(frame)

    local inputFrame = frame:FindFirstChild("InputFrame")::Frame
    if not inputFrame then
        return
    end

    local inputFrameMain = inputFrame:FindFirstChild("Frame")::Frame
    if not inputFrameMain then
        return
    end

    local roundFrame = inputFrameMain:FindFirstChild("RoundFrame")::Frame
    if not roundFrame then
        return
    end

    roundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

    local textFrame = frame:FindFirstChild("TextFrame")::Frame
    if not textFrame then
        return
    end

    local actionText = textFrame:FindFirstChild("ActionText")::TextLabel
    local objectText = textFrame:FindFirstChild("ObjectText")::TextLabel

    if not actionText or not objectText then
        return
    end

    actionText.Font = Enum.Font.SourceSansBold
    objectText.Font = Enum.Font.SourceSansBold

    actionText.TextSize = 30
    objectText.TextSize = 30

    local actionStroke = Instance.new("UIStroke")
    local objectStroke = Instance.new("UIStroke")

    actionStroke.Thickness = 3
    objectStroke.Thickness = 3

    actionStroke.Parent = actionText
    objectStroke.Parent = objectText

    -- Keep strokes in sync with label fade (both on show and hide)
    local function syncActionStroke()
        actionStroke.Transparency = actionText.TextTransparency
    end
    local function syncObjectStroke()
        objectStroke.Transparency = objectText.TextTransparency
    end
    -- Set initial values and hook changes
    syncActionStroke()
    syncObjectStroke()
    local actionConn = actionText:GetPropertyChangedSignal("TextTransparency"):Connect(syncActionStroke)
    local objectConn = objectText:GetPropertyChangedSignal("TextTransparency"):Connect(syncObjectStroke)

    prompt:SetAttribute("Setup", true)

    prompts[prompt] = true
    prompt.Destroying:Connect(function()
        prompts[prompt] = nil
        pcall(function() actionConn:Disconnect() end)
        pcall(function() objectConn:Disconnect() end)
    end)
end

for _, child in proximityPrompts:GetChildren() do
    if child:IsA("BillboardGui") then
        setupPrompt(child)
    end
end

proximityPrompts.ChildAdded:Connect(function(child)
    if child:IsA("BillboardGui") then
        setupPrompt(child)
    end
end)

-- Ensure we win against any last-second engine tweens by applying before UI draw
Functions.RenderStepped(function()
    for prompt, _ in prompts do
        local frame = prompt:FindFirstChild("Frame")::Frame
        if frame then
            if frame.BackgroundTransparency ~= 1 then
                frame.BackgroundTransparency = 1
            end
        end
    end
end, nil, true, nil, Enum.RenderPriority.First.Value)