--!strict

local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = require(ReplicatedStorage.Library.Functions)

export type Options = {[string]: any}

local localPlayer = game.Players.LocalPlayer

-- Single render step with registry of animated fish
local registry: {[Model]: {
    baseCFrame: CFrame,
    startTime: number,
    options: Options,
}} = {}

local stepHandle: any = nil
local syncTime = workspace:GetServerTimeNow()

local function ensureStep()
    if stepHandle and stepHandle.IsConnected and stepHandle:IsConnected() then
        return
    end
    stepHandle = Functions.RenderStepped(function(_dt: number, _t: number)
        if next(registry) == nil then
            -- Nothing to animate; stop until new entries added
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

            local carryingFishUID = localPlayer:GetAttribute("CarryingFishUID")
            if carryingFishUID and carryingFishUID == model:GetAttribute("UID") then
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
    end, nil, false, true, Enum.RenderPriority.First.Value)
end

local function animate(model: Model, opts: Options?)
    if not model or not model:IsA("Model") then
        warn("FishAnimations: model must be a Model")
        return function() end
    end

    local startTime = workspace:GetServerTimeNow() * math.random()
    if model:GetAttribute("PedestalFish") then
        print("found pedestal fish")
        startTime = syncTime
    end

    registry[model] = {
        baseCFrame = model:GetPivot(),
        startTime = startTime,
        options = opts or {} :: Options,
    }

    ensureStep()

    -- Return a cleanup function to unregister this model
    return function()
        if model:GetAttribute("PedestalFish") then
            print("removed pedes")
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