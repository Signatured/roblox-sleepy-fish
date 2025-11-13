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
local Audio = require(ReplicatedStorage.Library.Audio)

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

-- Event effect instances
local yingYangPortal: BasePart? = nil
local sky: Instance? = nil
local colorCorrection: ColorCorrectionEffect? = nil
local yingYangParticles: BasePart? = nil

-- Event state tracking
local isYingYangRunning = false
local isYingYangStarting = false

-- Event color storage for parts
local originalColors: {[BasePart]: Color3} = {}

-- GUI elements
local eventGuis: {SurfaceGui} = {}

local function updateEventGuis()
    -- Always show YingYang event status
    local eventData = Directory.MutationEvents["YingYang"]
    if not eventData then return end
    
    local now = getESTTime()
    local text = ""
    
    if isEventActive and currentEventId == "YingYang" and eventEndTime then
        local timeRemaining = math.max(0, eventEndTime - now)
        text = `{eventData.DisplayName} Event ending in {Functions.FormatTime(timeRemaining)}`
    elseif nextEventTime then
        local timeUntilNext = math.max(0, nextEventTime - now)
        local hexColor = string.format("#%02X%02X%02X", 
            math.floor(eventData.Color.R * 255),
            math.floor(eventData.Color.G * 255),
            math.floor(eventData.Color.B * 255))
        text = `<font color="{hexColor}">{eventData.DisplayName} Event</font> in {Functions.FormatTime(timeUntilNext)}`
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


local function startYingYangEvent()
    -- Prevent multiple starts
    if isYingYangRunning or isYingYangStarting then 
        warn("[MutationEvent] YingYang event already running or starting, ignoring duplicate start")
        return 
    end
    
    local eventData = Directory.MutationEvents["YingYang"]
    if not eventData then return end
    
    isYingYangStarting = true
    isYingYangRunning = true
    
    -- Send notification
    NotificationCmds.Message("Balance shifts... the Ying Yang awakens!", {
        Color = eventData.Color,
        Time = 10,
        Sound = "rbxassetid://125840884527985"
    })

    task.wait(3)
    
    -- Clone and setup Black Hole
    local eventFolder = Assets:FindFirstChild("YingYang")
    local yingYangPortalTemplate = eventFolder and eventFolder:FindFirstChild("YingYangPortal")
    if yingYangPortalTemplate and yingYangPortalTemplate:IsA("BasePart") then
        yingYangPortal = yingYangPortalTemplate:Clone() :: BasePart
        if yingYangPortal then
            yingYangPortal.Parent = DEBRIS

            Audio.Play("rbxassetid://111689316568748", yingYangPortal, 1, 1.5, 450)

            -- local sound = yingYangPortal:FindFirstChild("Sound")::Sound?
            -- if sound then
            --     sound.Playing = true
            -- end
        end
    end
    
    -- task.wait(3)
    
    -- Clone sky
    local yingYangFolder2 = Assets:FindFirstChild("YingYang")
    local skyTemplate = yingYangFolder2 and yingYangFolder2:FindFirstChild("YingYangSky")
    if skyTemplate then
        sky = skyTemplate:Clone()
        if sky then
            sky.Parent = Lighting
        end
    end
    
    -- Change colors of parts with EventColor attribute
    local yingYangData = Directory.MutationEvents["YingYang"]
    if yingYangData then
        local THINGS = workspace:FindFirstChild("__THINGS")
        if THINGS then
            for _, obj in ipairs(THINGS:GetDescendants()) do
                if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj:GetAttribute("EventColor") then
                    local part = obj :: BasePart
                    -- Store original color
                    originalColors[part] = part.Color
                    -- Tween to YingYang color
                    local tween = TweenService:Create(part,
                        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Color = yingYangData.Color}
                    )
                    tween:Play()
                end
            end
        end
    end
    
    -- Get ColorCorrection and tween TintColor
    colorCorrection = Lighting:FindFirstChild("ColorCorrection")
    if colorCorrection and colorCorrection:IsA("ColorCorrectionEffect") then
        local tween = TweenService:Create(colorCorrection, 
            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TintColor = Color3.fromRGB(209, 178, 255)}
        )
        tween:Play()
    end
    
    -- Clone YingYangParticles
    local yingYangParticlesTemplate = yingYangFolder2 and yingYangFolder2:FindFirstChild("YingYangParticles")
    
    if yingYangParticlesTemplate and yingYangParticlesTemplate:IsA("BasePart") then
        yingYangParticles = yingYangParticlesTemplate:Clone() :: BasePart
        if yingYangParticles then
            yingYangParticles.Parent = DEBRIS
        end
    end

    -- Clone ghost particles for water
    local topLayer = workspace:WaitForChild("__THINGS"):FindFirstChild("TopLayer")
    local yingYangGhostParticles = yingYangFolder2 and yingYangFolder2:FindFirstChild("TopLayerParticles")
    if yingYangGhostParticles then
        for _, particle in ipairs(yingYangGhostParticles:GetChildren()) do
            if particle:IsA("ParticleEmitter") then
                local cloned = particle:Clone()
                cloned.Parent = topLayer
            end
        end
    end
    
    -- Mark startup as complete
    isYingYangStarting = false
end

local function endYingYangEvent()
    -- Prevent ending if not running
    if not isYingYangRunning then 
        warn("[MutationEvent] YingYang event not running, ignoring end request")
        return 
    end
    
    -- Wait for startup process to complete if it's still running
    while isYingYangStarting do
        task.wait(0.1)
    end
    
    -- Turn on whirlpool particles for 3 seconds
    if yingYangPortal then
        Audio.Play("rbxassetid://111689316568748", yingYangPortal, 1, 1.5, 450)
        
        task.wait(6)
        setParticlesEnabled(yingYangPortal, false)
    end
    
    -- Turn off particles for YingYangParticles
    if yingYangParticles then
        setParticlesEnabled(yingYangParticles, false)
    end
    
    -- Remove sky
    if sky then
        sky:Destroy()
        sky = nil
    end
    
    -- Restore original colors of parts with EventColor attribute
    for part, originalColor in pairs(originalColors) do
        if part and part.Parent then
            local tween = TweenService:Create(part,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Color = originalColor}
            )
            tween:Play()
        end
    end
    -- Clear the color storage
    originalColors = {}
    
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
    if yingYangPortal then
        setParticlesEnabled(yingYangPortal, false)
    end

    local topLayer = workspace:WaitForChild("__THINGS"):FindFirstChild("TopLayer")
    for _, particle in ipairs(topLayer:GetChildren()) do
        if particle:IsA("ParticleEmitter") then
            particle.Enabled = false
        end
    end
    
    task.wait(3)
    
    -- Destroy all cloned parts
    if yingYangPortal then
        yingYangPortal:Destroy()
        yingYangPortal = nil
    end
    if yingYangParticles then
        yingYangParticles:Destroy()
        yingYangParticles = nil
    end
    for _, particle in ipairs(topLayer:GetChildren()) do
        if particle:IsA("ParticleEmitter") then
            particle:Destroy()
        end
    end
    
    -- Reset event state
    isYingYangRunning = false
    isYingYangStarting = false
end

-- Network event handlers
Network.Fired("MutationEvent_Start", function(eventId: string, startTime: number, endTime: number)
    isEventActive = true
    currentEventId = eventId
    _eventStartTime = startTime
    eventEndTime = endTime
    
    if eventId == "YingYang" then
        task.spawn(startYingYangEvent)
    end
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_End", function(eventId: string)
    if eventId == "YingYang" then
        task.spawn(endYingYangEvent)
    end
    
    isEventActive = false
    currentEventId = nil
    _eventStartTime = nil
    eventEndTime = nil
    -- Don't reset nextEventTime here - we need to get the updated time from server
    
    -- Request updated status from server to get the next event time
    task.spawn(function()
        task.wait(0.1) -- Small delay to ensure server has updated
        Network.Fire("MutationEvent_GetStatus")
    end)
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_Status", function(active: boolean, eventId: string?, startTime: number?, endTime: number?, nextTime: number?)
    isEventActive = active
    currentEventId = eventId
    _eventStartTime = startTime
    eventEndTime = endTime
    nextEventTime = nextTime
    
    -- If event is currently active, start it immediately
    if active and eventId == "YingYang" then
        task.spawn(startYingYangEvent)
    end
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_UpdateEndTime", function(eventId: string, newEndTime: number)
    -- Update the end time for the current event
    if isEventActive and currentEventId == eventId then
        eventEndTime = newEndTime
        updateEventGuis()
        print("[MutationEvent] End time updated to", newEndTime)
    end
end)

-- Setup EventGui using TagHook
TagHook("EventGui", function(gui: SurfaceGui)
    if not gui:IsA("SurfaceGui") then
        return function() end
    end
    
    table.insert(eventGuis, gui)
    
    -- Initialize with default YingYang display
    local eventData = Directory.MutationEvents["YingYang"]
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

--[[
    Public API to check if YingYang event is currently active.
    
    @return boolean - Whether YingYang event is active
]]
function MutationEventCmds.IsYingYangActive(): boolean
    return isEventActive and currentEventId == "YingYang"
end

--[[
    Public API to get the current event status.
    
    @return boolean, string? - Whether any event is active and the event ID
]]
function MutationEventCmds.GetCurrentEvent(): (boolean, string?)
    return isEventActive, currentEventId
end

-- Initialize when player loads
task.spawn(function()
    -- Wait for player to have Loaded attribute
    while not player:GetAttribute("LoadingScreenComplete") do
        task.wait(0.5)
    end
    
    -- Wait 1.5 seconds then ask server for status
    task.wait(1.5)
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
