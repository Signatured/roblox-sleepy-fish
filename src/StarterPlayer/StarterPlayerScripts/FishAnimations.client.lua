--!strict

local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = require(ReplicatedStorage.Library.Functions)

export type Options = {[string]: any}

local localPlayer = game.Players.LocalPlayer

local function animate(model: Model, opts: Options?)
    if not model or not model:IsA("Model") then
        warn("FishAnimations: model must be a Model")
        return function() end
    end

    local options = opts or {} :: Options
    local bobAmp = (options.BobAmplitude :: number?) or 1
    -- Peak-to-bottom = 3s => full period = 6s => bobSpeed = 1/6 Hz
    local bobSpeed = (options.BobSpeed :: number?) or (1/6)          -- Hz (T=6s)
    local swayAmp = (options.SwayAmplitude :: number?) or 1
    local swaySpeed = (options.SwaySpeed :: number?) or 0.3         -- Hz
    local rollMax = math.rad((options.RollMaxDeg :: number?) or 10) -- radians
    local yawMax = math.rad((options.YawMaxDeg :: number?) or 10)   -- radians

    local baseCFrame = model:GetPivot()
    local startTime = os.clock()

    local step = Functions.RenderStepped(function(_dt: number, t: number)
        if not model.Parent then
            return
        end

        if localPlayer:GetAttribute("CarryingFishUID") == model:GetAttribute("UID") then
            return
        end

        local elapsed = os.clock() - startTime
        local omega = 2 * math.pi * bobSpeed

        -- Bob: use cosine so t=0 starts at peak
        local bob = math.cos(omega * elapsed) * bobAmp
        local sway = math.sin(2 * math.pi * swaySpeed * elapsed + math.pi/3) * swayAmp

        -- Yaw: +10deg at top, -10deg at middle, +10deg at bottom -> cos(2*omega*t)
        local yaw = math.cos(2 * omega * elapsed) * yawMax

        -- Roll: 0 at top, then tilt left, then right, then 0 at bottom across half-cycle
        -- Use -sin(ωt) * sin(2ωt) pattern to achieve left then right within [0, T/2]
        local roll = (-math.sin(omega * elapsed) * math.sin(2 * omega * elapsed)) * rollMax

        -- Apply yaw, then translate, then roll
        local newCF = baseCFrame * CFrame.Angles(0, yaw, 0) * CFrame.new(sway, bob, 0) * CFrame.Angles(0, 0, roll)
        model:PivotTo(newCF)
    end, nil, false, true, Enum.RenderPriority.First.Value)

    -- Return a cleanup function
    return function()
        if step and step.IsConnected and step:IsConnected() then
            step:Disconnect()
        end
    end
end

Functions.TagHook("SwimmingFish", animate)