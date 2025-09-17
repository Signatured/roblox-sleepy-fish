--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)
local Functions = require(Library.Functions)
local TagHook = require(Library.Functions.TagHook)
local NotificationCmds = require(Library.Client.NotificationCmds)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local player = Players.LocalPlayer
local DEBRIS = workspace:WaitForChild("__DEBRIS")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local MutationEventCmds = {}

-- Configuration
local EST_OFFSET = -5 * 3600 -- EST is UTC-5 (in seconds)

-- State
local isEventActive = false
local currentEventId: string? = nil
local _eventStartTime: number? = nil
local eventEndTime: number? = nil
local nextEventTime: number? = nil

local function getESTTime(): number
    return DateTime.now().UnixTimestamp + EST_OFFSET
end

-- Blood Moon effect instances
local bloodMoonWhirlpool: BasePart? = nil
local redNightSky: Instance? = nil
local colorCorrection: ColorCorrectionEffect? = nil
local bloodMoonParticles1: BasePart? = nil
local bloodMoonParticles2: BasePart? = nil

-- GUI elements
local eventGuis: {SurfaceGui} = {}

local function updateEventGuis()
    -- Always show Blood Moon event status
    local eventData = Directory.MutationEvents["Blood Moon"]
    if not eventData then return end
    
    local now = getESTTime()
    local text = ""
    
    if isEventActive and currentEventId == "Blood Moon" and eventEndTime then
        local timeRemaining = math.max(0, eventEndTime - now)
        text = `{eventData.DisplayName} Event ending in {Functions.FormatTime(timeRemaining)}`
    elseif nextEventTime then
        local timeUntilNext = math.max(0, nextEventTime - now)
        local hexColor = string.format("#%02X%02X%02X", 
            math.floor(eventData.Color.R * 255),
            math.floor(eventData.Color.G * 255),
            math.floor(eventData.Color.B * 255))
        text = `<font color="{hexColor}">{eventData.DisplayName}</font> in {Functions.FormatTime(timeUntilNext)}`
    end
    
    for _, gui in ipairs(eventGuis) do
        if gui and gui.Parent then
            local frame = gui:FindFirstChild("Frame")
            local event = frame and frame:FindFirstChild("Event")
            local textLabel = event and event:FindFirstChild("TextLabel")
            if textLabel and textLabel:IsA("TextLabel") then
                textLabel.Text = text
            end
        end
    end
end

local function setParticlesEnabled(parent: Instance, enabled: boolean)
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("ParticleEmitter") then
            child.Enabled = enabled
        end
    end
end

local function startBloodMoonEvent()
    local eventData = Directory.MutationEvents["Blood Moon"]
    if not eventData then return end
    
    -- Send notification
    NotificationCmds.Message("The Blood Moon is rising...", {
        Color = eventData.Color,
        Time = 10
    })
    
    -- Clone and setup BloodMoonWhirlpool
    local bloodMoonFolder = Assets:FindFirstChild("BloodMoon")
    local whirlpoolTemplate = bloodMoonFolder and bloodMoonFolder:FindFirstChild("BloodMoonWhirlpool")
    if whirlpoolTemplate and whirlpoolTemplate:IsA("BasePart") then
        bloodMoonWhirlpool = whirlpoolTemplate:Clone() :: BasePart
        if bloodMoonWhirlpool then
            bloodMoonWhirlpool.Parent = DEBRIS
            -- Turn off particles initially
            setParticlesEnabled(bloodMoonWhirlpool, false)
        end
        
        -- Remove after 3 seconds
        task.spawn(function()
            task.wait(3)
            if bloodMoonWhirlpool then
                bloodMoonWhirlpool:Destroy()
                bloodMoonWhirlpool = nil
            end
        end)
    end
    
    task.wait(3)
    
    -- Clone RedNight sky
    local bloodMoonFolder2 = Assets:FindFirstChild("BloodMoon")
    local skyTemplate = bloodMoonFolder2 and bloodMoonFolder2:FindFirstChild("RedNight")
    if skyTemplate then
        redNightSky = skyTemplate:Clone()
        if redNightSky then
            redNightSky.Parent = Lighting
        end
    end
    
    -- Get ColorCorrection and tween TintColor
    colorCorrection = Lighting:FindFirstChild("ColorCorrection")
    if colorCorrection and colorCorrection:IsA("ColorCorrectionEffect") then
        local tween = TweenService:Create(colorCorrection, 
            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TintColor = Color3.fromRGB(255, 171, 172)}
        )
        tween:Play()
    end
    
    -- Clone BloodmoonParticles1 and BloodmoonParticles2
    local bloodMoonFolder3 = Assets:FindFirstChild("BloodMoon")
    local particles1Template = bloodMoonFolder3 and bloodMoonFolder3:FindFirstChild("BloodmoonParticles1")
    local particles2Template = bloodMoonFolder3 and bloodMoonFolder3:FindFirstChild("BloodmoonParticles2")
    
    if particles1Template and particles1Template:IsA("BasePart") then
        bloodMoonParticles1 = particles1Template:Clone() :: BasePart
        if bloodMoonParticles1 then
            bloodMoonParticles1.Parent = DEBRIS
        end
    end
    
    if particles2Template and particles2Template:IsA("BasePart") then
        bloodMoonParticles2 = particles2Template:Clone() :: BasePart
        if bloodMoonParticles2 then
            bloodMoonParticles2.Parent = DEBRIS
        end
    end
end

local function endBloodMoonEvent()
    -- Turn on whirlpool particles for 3 seconds
    if bloodMoonWhirlpool then
        setParticlesEnabled(bloodMoonWhirlpool, true)
        task.wait(3)
        setParticlesEnabled(bloodMoonWhirlpool, false)
    end
    
    -- Turn off particles for BloodmoonParticles1 and BloodmoonParticles2
    if bloodMoonParticles1 then
        setParticlesEnabled(bloodMoonParticles1, false)
    end
    if bloodMoonParticles2 then
        setParticlesEnabled(bloodMoonParticles2, false)
    end
    
    -- Remove RedNight sky
    if redNightSky then
        redNightSky:Destroy()
        redNightSky = nil
    end
    
    -- Tween ColorCorrection back to normal
    if colorCorrection and colorCorrection:IsA("ColorCorrectionEffect") then
        local tween = TweenService:Create(colorCorrection,
            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TintColor = Color3.fromRGB(255, 255, 255)}
        )
        tween:Play()
        tween.Completed:Wait()
    end
    
    -- Turn off whirlpool particles again
    if bloodMoonWhirlpool then
        setParticlesEnabled(bloodMoonWhirlpool, false)
    end
    
    task.wait(3)
    
    -- Destroy all cloned parts
    if bloodMoonWhirlpool then
        bloodMoonWhirlpool:Destroy()
        bloodMoonWhirlpool = nil
    end
    if bloodMoonParticles1 then
        bloodMoonParticles1:Destroy()
        bloodMoonParticles1 = nil
    end
    if bloodMoonParticles2 then
        bloodMoonParticles2:Destroy()
        bloodMoonParticles2 = nil
    end
end

-- Network event handlers
Network.Fired("MutationEvent_Start", function(eventId: string, startTime: number, endTime: number)
    isEventActive = true
    currentEventId = eventId
    _eventStartTime = startTime
    eventEndTime = endTime
    
    if eventId == "Blood Moon" then
        task.spawn(startBloodMoonEvent)
    end
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_End", function(eventId: string)
    if eventId == "Blood Moon" then
        task.spawn(endBloodMoonEvent)
    end
    
    isEventActive = false
    currentEventId = nil
    _eventStartTime = nil
    eventEndTime = nil
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_Status", function(active: boolean, eventId: string?, startTime: number?, endTime: number?, nextTime: number?)
    isEventActive = active
    currentEventId = eventId
    _eventStartTime = startTime
    eventEndTime = endTime
    nextEventTime = nextTime
    
    -- If event is currently active, start it immediately
    if active and eventId == "Blood Moon" then
        task.spawn(startBloodMoonEvent)
    end
    
    updateEventGuis()
end)

-- Setup EventGui using TagHook
TagHook("EventGui", function(gui: SurfaceGui)
    if not gui:IsA("SurfaceGui") then
        return function() end
    end
    
    table.insert(eventGuis, gui)
    
    -- Initialize with default Blood Moon display
    local eventData = Directory.MutationEvents["Blood Moon"]
    if eventData then
        local frame = gui:FindFirstChild("Frame")
        local event = frame and frame:FindFirstChild("Event")
        local textLabel = event and event:FindFirstChild("TextLabel")
        if textLabel and textLabel:IsA("TextLabel") then
            local hexColor = string.format("#%02X%02X%02X", 
                math.floor(eventData.Color.R * 255),
                math.floor(eventData.Color.G * 255),
                math.floor(eventData.Color.B * 255))
            textLabel.Text = `<font color="{hexColor}">{eventData.DisplayName}</font> - Loading...`
        end
    end
    
    updateEventGuis()
    
    return function()
        local index = table.find(eventGuis, gui)
        if index then
            table.remove(eventGuis, index)
        end
    end
end)

-- Initialize when player loads
task.spawn(function()
    -- Wait for player to have Loaded attribute
    while not player:GetAttribute("Loaded") do
        task.wait(1)
    end
    
    -- Wait 3 seconds then ask server for status
    task.wait(3)
    Network.Fire("MutationEvent_GetStatus")
end)

-- Always update GUI every second regardless of server status
task.spawn(function()
    while true do
        task.wait(1)
        updateEventGuis()
    end
end)

return MutationEventCmds
