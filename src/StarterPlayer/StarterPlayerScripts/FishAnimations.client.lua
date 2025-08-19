--!strict

local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = require(ReplicatedStorage.Library.Functions)

export type Options = {[string]: any}

local _localPlayer = game.Players.LocalPlayer

-- Single render step with registry of animated fish
local registry: {[Model]: {
    baseCFrame: CFrame,
    startTime: number,
    options: Options,
    attrConn: RBXScriptConnection?,
}} = {}

local stepHandle: any = nil
local syncTime = workspace:GetServerTimeNow()

-- Highlight animation targets
local ROOT = workspace:WaitForChild("__THINGS")
local goldHighlights: {Highlight} = {}
local rainbowHighlights: {Highlight} = {}
local shinyHighlights: {Highlight} = {}
local lastScanTime = 0

local function tryGetHighlight(folderName: string, typeName: string): Highlight?
    local folder = ROOT:FindFirstChild(folderName)
    local model = folder and folder:FindFirstChild(typeName)
    local hl = model and model:FindFirstChild("Highlight")
    if hl and hl:IsA("Highlight") then
        return hl
    end
    return nil
end

local function refreshHighlights()
    -- Clear arrays and repopulate; called infrequently
    table.clear(goldHighlights)
    table.clear(rainbowHighlights)
    table.clear(shinyHighlights)

    local hl = tryGetHighlight("PlotFish", "Gold"); if hl then table.insert(goldHighlights, hl) end
    hl = tryGetHighlight("SwimmingFish", "Gold"); if hl then table.insert(goldHighlights, hl) end
    hl = tryGetHighlight("PlotFish", "Rainbow"); if hl then table.insert(rainbowHighlights, hl) end
    hl = tryGetHighlight("SwimmingFish", "Rainbow"); if hl then table.insert(rainbowHighlights, hl) end
    hl = tryGetHighlight("PlotFish", "Shiny"); if hl then table.insert(shinyHighlights, hl) end
    hl = tryGetHighlight("SwimmingFish", "Shiny"); if hl then table.insert(shinyHighlights, hl) end
    lastScanTime = os.clock()
end

local function haveAnyHighlights(): boolean
    return (#goldHighlights + #rainbowHighlights + #shinyHighlights) > 0
end

local function ensureStep()
    if stepHandle and stepHandle.IsConnected and stepHandle:IsConnected() then
        return
    end
    stepHandle = Functions.RenderStepped(function(_dt: number, _t: number)
        -- Rescan highlights occasionally in case models stream in
        if os.clock() - lastScanTime > 2 then
            refreshHighlights()
        end

        if next(registry) == nil and not haveAnyHighlights() then
            if stepHandle and stepHandle.IsConnected and stepHandle:IsConnected() then
                stepHandle:Disconnect()
            end
            return
        end

        for _m, data in pairs(registry :: {[Model]: any}) do
            local model = _m :: any
            if not model or not model.Parent then
                registry[model] = nil
                continue
            end

            if model:GetAttribute("Carrying") then
                continue
            end

            local opts = data.options
            local bobAmp = (opts.BobAmplitude :: number?) or 1
            local bobSpeed = (opts.BobSpeed :: number?) or (1/6)
            local swayAmp = (opts.SwayAmplitude :: number?) or 1
            local swaySpeed = (opts.SwaySpeed :: number?) or 0.3
            local rollMax = math.rad((opts.RollMaxDeg :: number?) or 10)
            local yawMax = math.rad((opts.YawMaxDeg :: number?) or 10)

            local elapsed = workspace:GetServerTimeNow() - data.startTime
            local omega = 2 * math.pi * bobSpeed

            local bob = math.cos(omega * elapsed) * bobAmp
            local sway = math.sin(2 * math.pi * swaySpeed * elapsed + math.pi/3) * swayAmp
            local yaw = math.cos(2 * omega * elapsed) * yawMax
            local roll = (-math.sin(omega * elapsed) * math.sin(2 * omega * elapsed)) * rollMax

            local newCF = data.baseCFrame * CFrame.Angles(0, yaw, 0) * CFrame.new(sway, bob, 0) * CFrame.Angles(0, 0, roll)
            model:PivotTo(newCF)
        end

        -- Highlights animation
        local now = os.clock()
        -- Gold: FillTransparency ping-pong between 0.4 and 0.6 every 2 seconds
        local goldMid, goldAmp, goldT = 0.7, 0.1, 2
        local goldVal = goldMid + goldAmp * math.sin(2 * math.pi * (now / goldT))
        for _, hl in ipairs(goldHighlights) do
            if hl and hl.Parent then
                hl.FillTransparency = math.clamp(goldVal, 0, 1)
            end
        end

        -- Shiny: FillTransparency ping-pong between 0.5 and 0.7 every 2 seconds
        local shinyMid, shinyAmp, shinyT = 0.7, 0.1, 2
        local shinyVal = shinyMid + shinyAmp * math.sin(2 * math.pi * (now / shinyT))
        for _, hl in ipairs(shinyHighlights) do
            if hl and hl.Parent then
                hl.FillTransparency = math.clamp(shinyVal, 0, 1)
            end
        end

        -- Rainbow: FillColor cycles every 5 seconds
        local hue = (now % 5) / 5
        local color = Color3.fromHSV(hue, 1, 1)
        for _, hl in ipairs(rainbowHighlights) do
            if hl and hl.Parent then
                hl.FillColor = color
            end
        end
    end, nil, false, true, Enum.RenderPriority.First.Value)
end

local function animate(model: Model, opts: Options?)
    if not model or not model:IsA("Model") then
        warn("FishAnimations: model must be a Model")
        return function() end
    end

    local startTime = workspace:GetServerTimeNow() * math.random()
    if model:GetAttribute("PedestalFish") then
        startTime = syncTime
    end

    local initialBase = model:GetPivot()
    local attrCF = model:GetAttribute("CFrame")
    if typeof(attrCF) == "CFrame" then
        initialBase = attrCF :: CFrame
    end
    registry[model] = {
        baseCFrame = initialBase,
        startTime = startTime,
        options = opts or {} :: Options,
        attrConn = nil,
    }

    -- Update base when server updates model attribute "CFrame" (e.g., on drop)
    registry[model].attrConn = model:GetAttributeChangedSignal("CFrame"):Connect(function()
        local cf = model:GetAttribute("CFrame")
        if typeof(cf) == "CFrame" then
            local rec = registry[model]
            if rec then
                rec.baseCFrame = cf :: CFrame
                rec.startTime = workspace:GetServerTimeNow()
            end
        end
    end)

    ensureStep()

    -- Return a cleanup function to unregister this model
    return function()
        local rec = registry[model]
        if rec and rec.attrConn then
            (rec.attrConn :: RBXScriptConnection):Disconnect()
        end
        registry[model] = nil
        if next(registry) == nil then
            if stepHandle and stepHandle.IsConnected and stepHandle:IsConnected() then
                stepHandle:Disconnect()
            end
        end
    end
end

Functions.TagHook("SwimmingFish", animate)

Functions.TagHook("RainbowFishType", function(label: TextLabel)
    task.defer(function()
        if label.Text == "Rainbow" then
            Functions.Rainbow(label, "TextColor3")
        end
    end)

    return function()  end
end)

-- Seed highlights and ensure the step is running even if no swimming fish are present
refreshHighlights()
ensureStep()