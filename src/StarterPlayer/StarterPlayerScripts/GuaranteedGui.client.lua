--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = require(ReplicatedStorage.Library.Functions)

-- Periods in seconds
local LEGENDARY_PERIOD = 5 * 60 -- 5 minutes
local MYTHICAL_PERIOD = 15 * 60 -- every 15 minutes

local function nowUnix(): number
    return DateTime.now().UnixTimestamp
end

local function nextMythicalSpawn(): number
    local now = nowUnix()
    local nextTop = (math.floor(now / MYTHICAL_PERIOD) + 1) * MYTHICAL_PERIOD
    return nextTop
end

local function nextFromBottomOfHour(period: number): number
    local now = nowUnix()
    local hourStart = math.floor(now / 3600) * 3600
    local bottom = hourStart + 1800 -- :30 of the hour
    if now <= bottom then
        return bottom
    end
    local k = math.ceil((now - bottom) / period)
    return bottom + k * period
end

local function setupSurfaceGui(gui: SurfaceGui)
    local frame = gui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return function() end end

    local legendary = frame:FindFirstChild("Legendary")
    local mythical = frame:FindFirstChild("Mythical")

    local legendaryTimer = legendary and legendary:FindFirstChild("TextLabel")
    local mythicalTimer = mythical and mythical:FindFirstChild("TextLabel")
    assert(mythicalTimer)

    Functions.GradientScroll(mythicalTimer:FindFirstChild("RainbowGradientWrapped")::UIGradient, 2.5)

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not gui or not gui.Parent then
            if conn then conn:Disconnect() end
            return
        end
        local now = nowUnix()

        local legNext = nextFromBottomOfHour(LEGENDARY_PERIOD)
        local mytNext = nextMythicalSpawn()

        local legLeft = math.max(0, legNext - now)
        local mytLeft = math.max(0, mytNext - now)

        if legendaryTimer and legendaryTimer:IsA("TextLabel") then
            legendaryTimer.Text = `Gauranteed <font color="##ff8800">Legendary</font> in {Functions.FormatTime(legLeft)}`
        end
        if mythicalTimer and mythicalTimer:IsA("TextLabel") then
            mythicalTimer.Text = `Gauranteed Mythical in {Functions.FormatTime(mytLeft)}`
        end
    end)

    return function()
        if conn then conn:Disconnect() end
    end
end

Functions.TagHook("GuaranteedGui", function(gui: SurfaceGui)
    return setupSurfaceGui(gui)
end)


