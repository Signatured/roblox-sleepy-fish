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
local galaxyBlackHole: BasePart? = nil
local sky: Instance? = nil
local colorCorrection: ColorCorrectionEffect? = nil
local galaxyParticles: BasePart? = nil

-- Event state tracking
local isGalaxyRunning = false
local isGalaxyStarting = false

-- Event color storage for parts
local originalColors: {[BasePart]: Color3} = {}

-- GUI elements
local eventGuis: {SurfaceGui} = {}

local function updateEventGuis()
    -- Always show Galaxy event status
    local eventData = Directory.MutationEvents["Galaxy"]
    if not eventData then return end
    
    local now = getESTTime()
    local text = ""
    
    if isEventActive and currentEventId == "Galaxy" and eventEndTime then
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


local function startGalaxyEvent()
    -- Prevent multiple starts
    if isGalaxyRunning or isGalaxyStarting then 
        warn("[MutationEvent] Galaxy event already running or starting, ignoring duplicate start")
        return 
    end
    
    local eventData = Directory.MutationEvents["Galaxy"]
    if not eventData then return end
    
    isGalaxyStarting = true
    isGalaxyRunning = true
    
    -- Send notification
    NotificationCmds.Message("The Galaxy Portal is opening...", {
        Color = eventData.Color,
        Time = 10,
        Sound = "rbxassetid://131321022475059"
    })

    task.wait(8.5)
    
    -- Clone and setup Black Hole
    local eventFolder = Assets:FindFirstChild("Galaxy")
    local blackHoleTemplate = eventFolder and eventFolder:FindFirstChild("BlackHole")
    if blackHoleTemplate and blackHoleTemplate:IsA("BasePart") then
        galaxyBlackHole = blackHoleTemplate:Clone() :: BasePart
        if galaxyBlackHole then
            galaxyBlackHole.Parent = DEBRIS

            Audio.Play("rbxassetid://111689316568748", galaxyBlackHole, 1, 1.5, 450)

            local sound = galaxyBlackHole:FindFirstChild("Sound")::Sound?
            if sound then
                sound.Playing = true
            end
        end
    end
    
    -- task.wait(3)
    
    -- Clone sky
    local galaxyFolder2 = Assets:FindFirstChild("Galaxy")
    local skyTemplate = galaxyFolder2 and galaxyFolder2:FindFirstChild("GalaxySky")
    if skyTemplate then
        sky = skyTemplate:Clone()
        if sky then
            sky.Parent = Lighting
        end
    end
    
    -- Change colors of parts with EventColor attribute
    local galaxyData = Directory.MutationEvents["Galaxy"]
    if galaxyData then
        local THINGS = workspace:FindFirstChild("__THINGS")
        if THINGS then
            for _, obj in ipairs(THINGS:GetDescendants()) do
                if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj:GetAttribute("EventColor") then
                    local part = obj :: BasePart
                    -- Store original color
                    originalColors[part] = part.Color
                    -- Tween to galaxy color
                    local tween = TweenService:Create(part,
                        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Color = galaxyData.Color}
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
    
    -- Clone GalaxyParticles
    local galaxyParticlesTemplate = galaxyFolder2 and galaxyFolder2:FindFirstChild("GalaxyParticles")
    
    if galaxyParticlesTemplate and galaxyParticlesTemplate:IsA("BasePart") then
        galaxyParticles = galaxyParticlesTemplate:Clone() :: BasePart
        if galaxyParticles then
            galaxyParticles.Parent = DEBRIS
        end
    end
    
    -- Mark startup as complete
    isGalaxyStarting = false
end

local function endGalaxyEvent()
    -- Prevent ending if not running
    if not isGalaxyRunning then 
        warn("[MutationEvent] Galaxy event not running, ignoring end request")
        return 
    end
    
    -- Wait for startup process to complete if it's still running
    while isGalaxyStarting do
        task.wait(0.1)
    end
    
    -- Turn on whirlpool particles for 3 seconds
    if galaxyBlackHole then
        Audio.Play("rbxassetid://111689316568748", galaxyBlackHole, 1, 1.5, 450)
        
        task.wait(6)
        setParticlesEnabled(galaxyBlackHole, false)
    end
    
    -- Turn off particles for GalaxyParticles
    if galaxyParticles then
        setParticlesEnabled(galaxyParticles, false)
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
    if galaxyBlackHole then
        setParticlesEnabled(galaxyBlackHole, false)
    end
    
    task.wait(3)
    
    -- Destroy all cloned parts
    if galaxyBlackHole then
        galaxyBlackHole:Destroy()
        galaxyBlackHole = nil
    end
    if galaxyParticles then
        galaxyParticles:Destroy()
        galaxyParticles = nil
    end
    
    -- Reset event state
    isGalaxyRunning = false
    isGalaxyStarting = false
end

-- Network event handlers
Network.Fired("MutationEvent_Start", function(eventId: string, startTime: number, endTime: number)
    isEventActive = true
    currentEventId = eventId
    _eventStartTime = startTime
    eventEndTime = endTime
    
    if eventId == "Galaxy" then
        task.spawn(startGalaxyEvent)
    end
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_End", function(eventId: string)
    if eventId == "Galaxy" then
        task.spawn(endGalaxyEvent)
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
    if active and eventId == "Galaxy" then
        task.spawn(startGalaxyEvent)
    end
    
    updateEventGuis()
end)

-- Setup EventGui using TagHook
TagHook("EventGui", function(gui: SurfaceGui)
    if not gui:IsA("SurfaceGui") then
        return function() end
    end
    
    table.insert(eventGuis, gui)
    
    -- Initialize with default Galaxy display
    local eventData = Directory.MutationEvents["Galaxy"]
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
    Public API to check if Galaxy event is currently active.
    
    @return boolean - Whether Galaxy event is active
]]
function MutationEventCmds.IsGalaxyActive(): boolean
    return isEventActive and currentEventId == "Galaxy"
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
