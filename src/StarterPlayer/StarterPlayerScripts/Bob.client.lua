--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)

local TAG = "Bob"
local OMEGA = math.pi / 2 -- 4s full period (2s top->bottom)
local SPIN_OMEGA = 2 * math.pi / 10 -- 1 rotation every 10 seconds

TagHook(TAG, function(instance: Instance)
    local baseCFrame: CFrame
    local setCFrame: (cf: CFrame) -> ()

    if instance:IsA("BasePart") then
        local part = instance :: BasePart
        baseCFrame = part.CFrame
        setCFrame = function(cf: CFrame)
            part.CFrame = cf
        end
    elseif instance:IsA("Model") then
        local model = instance :: Model
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if not primary then
            return function() end
        end
        baseCFrame = model:GetPivot()
        setCFrame = function(cf: CFrame)
            model:PivotTo(cf)
        end
    else
        return function() end
    end

    local amplitudeAttr = (instance :: any):GetAttribute("BobAmplitude")
    local amplitude: number = (typeof(amplitudeAttr) == "number") and (amplitudeAttr :: number) or 1
    local noSpinAttr = (instance :: any):GetAttribute("NoSpin")
    local noSpin: boolean = (typeof(noSpinAttr) == "boolean") and (noSpinAttr :: boolean) or false
    local speedAttr = (instance :: any):GetAttribute("BobSpeed")
    local speed: number = (typeof(speedAttr) == "number") and (speedAttr :: number) or 1

    local startTime = workspace:GetServerTimeNow()
    local period = (2 * math.pi) / OMEGA -- 4 seconds
    local phaseOffsetSec = math.random() * period
    local conn = RunService.RenderStepped:Connect(function()
        if not instance.Parent then
            return
        end
        local t = (workspace:GetServerTimeNow() - startTime) + phaseOffsetSec
        local dy = amplitude * math.sin(OMEGA * speed * t)
        local cf = baseCFrame
        if not noSpin then
            local angle = SPIN_OMEGA * speed * t
            cf = cf * CFrame.Angles(0, angle, 0)
        end
        setCFrame(cf + Vector3.new(0, dy, 0))
    end)

    return function()
        pcall(function()
            setCFrame(baseCFrame)
        end)
        pcall(function()
            conn:Disconnect()
        end)
    end
end)


