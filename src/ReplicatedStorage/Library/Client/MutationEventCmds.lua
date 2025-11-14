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
local Signal = require(ReplicatedStorage.Library.Signal)

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
local yinYangPortal: BasePart? = nil
local sky: Instance? = nil
local colorCorrection: ColorCorrectionEffect? = nil
local yinYangParticles: BasePart? = nil

-- Event state tracking
local isYinYangRunning = false
local isYinYangStarting = false

-- Event color storage for parts
local originalColors: {[BasePart]: Color3} = {}

-- GUI elements
local eventGuis: {SurfaceGui} = {}

-- Grass color animation
local grassParts: {BasePart} = {}
local grassAnimationThread: thread? = nil
local startGrassAnimation: () -> ()
local stopGrassAnimation: () -> ()
local isPartyEventActive = false

-- Listen to signal from Party event to know when it's active
Signal.Fired("PartyEventActive"):Connect(function(isActive: boolean)
	isPartyEventActive = isActive
end)

local function updateEventGuis()
    -- Always show YinYang event status
    local eventData = Directory.MutationEvents["YinYang"]
    if not eventData then return end
    
    local now = getESTTime()
    local text = ""
    
    if isEventActive and currentEventId == "YinYang" and eventEndTime then
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


local function startYinYangEvent()
    -- Prevent multiple starts
    if isYinYangRunning or isYinYangStarting then 
        warn("[MutationEvent] YinYang event already running or starting, ignoring duplicate start")
        return 
    end
    
    local eventData = Directory.MutationEvents["YinYang"]
    if not eventData then return end
    
    isYinYangStarting = true
    isYinYangRunning = true
    
    -- Send notification
    NotificationCmds.Message("Balance shifts... the Yin Yang awakens!", {
        Color = eventData.Color,
        Time = 10,
        Sound = "rbxassetid://139100592181941"
    })

    task.wait(3)
    
    -- Clone and setup Black Hole
    local eventFolder = Assets:FindFirstChild("YinYang")
    local yinYangPortalTemplate = eventFolder and eventFolder:FindFirstChild("YinYangPortal")
    if yinYangPortalTemplate and yinYangPortalTemplate:IsA("BasePart") then
        yinYangPortal = yinYangPortalTemplate:Clone() :: BasePart
        if yinYangPortal then
            yinYangPortal.Parent = DEBRIS

            Audio.Play("rbxassetid://111689316568748", yinYangPortal, 1, 1.5, 450)

            -- local sound = yinYangPortal:FindFirstChild("Sound")::Sound?
            -- if sound then
            --     sound.Playing = true
            -- end
        end
    end
    
    -- task.wait(3)
    
    -- Clone sky
    local yinYangFolder2 = Assets:FindFirstChild("YinYang")
    local skyTemplate = yinYangFolder2 and yinYangFolder2:FindFirstChild("YinYangSky")
    if skyTemplate then
        sky = skyTemplate:Clone()
        if sky then
            sky.Parent = Lighting
        end
    end
    
    -- Change colors of parts with EventColor attribute
    local yinYangData = Directory.MutationEvents["YinYang"]
    if yinYangData then
        local function recolor(instance: Instance)
            for _, obj in ipairs(instance:GetDescendants()) do
                if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj:GetAttribute("EventColor") then
                    local part = obj :: BasePart
                    -- Store original color
                    originalColors[part] = part.Color
                    local color = yinYangData.UseAttributeColors and obj:GetAttribute("EventColor") or yinYangData.Color
                    -- Tween to YinYang color
                    local tween = TweenService:Create(part,
                        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Color = color}
                    )
                    tween:Play()
                end
            end
        end
        local THINGS = workspace:FindFirstChild("__THINGS")
        if THINGS then
            recolor(THINGS)
        end
        local MAP = workspace:FindFirstChild("Map")
        if MAP then
            recolor(MAP)
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
    
    -- Clone YinYangParticles
    local yinYangParticlesTemplate = yinYangFolder2 and yinYangFolder2:FindFirstChild("YinYangParticles")
    
    if yinYangParticlesTemplate and yinYangParticlesTemplate:IsA("BasePart") then
        yinYangParticles = yinYangParticlesTemplate:Clone() :: BasePart
        if yinYangParticles then
            yinYangParticles.Parent = DEBRIS
        end
    end

    -- Clone ghost particles for water
    local topLayer = workspace:WaitForChild("__THINGS"):FindFirstChild("TopLayer")
    local yinYangGhostParticles = yinYangFolder2 and yinYangFolder2:FindFirstChild("TopLayerParticles")
    if yinYangGhostParticles then
        for _, particle in ipairs(yinYangGhostParticles:GetChildren()) do
            if particle:IsA("ParticleEmitter") then
                local cloned = particle:Clone()
                cloned.Parent = topLayer
            end
        end
    end
    
    -- Mark startup as complete
    isYinYangStarting = false
end

local function endYinYangEvent()
    -- Prevent ending if not running
    if not isYinYangRunning then 
        warn("[MutationEvent] YinYang event not running, ignoring end request")
        return 
    end
    
    -- Wait for startup process to complete if it's still running
    while isYinYangStarting do
        task.wait(0.1)
    end
    
    -- Turn on whirlpool particles for 3 seconds
    if yinYangPortal then
        Audio.Play("rbxassetid://111689316568748", yinYangPortal, 1, 1.5, 450)
        
        task.wait(6)
        setParticlesEnabled(yinYangPortal, false)
    end
    
    -- Turn off particles for YinYangParticles
    if yinYangParticles then
        setParticlesEnabled(yinYangParticles, false)
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
    if yinYangPortal then
        setParticlesEnabled(yinYangPortal, false)
    end

    local topLayer = workspace:WaitForChild("__THINGS"):FindFirstChild("TopLayer")
    for _, particle in ipairs(topLayer:GetChildren()) do
        if particle:IsA("ParticleEmitter") then
            particle.Enabled = false
        end
    end
    
    task.wait(3)
    
    -- Destroy all cloned parts
    if yinYangPortal then
        yinYangPortal:Destroy()
        yinYangPortal = nil
    end
    if yinYangParticles then
        yinYangParticles:Destroy()
        yinYangParticles = nil
    end
    for _, particle in ipairs(topLayer:GetChildren()) do
        if particle:IsA("ParticleEmitter") then
            particle:Destroy()
        end
    end
    
    -- Reset event state
    isYinYangRunning = false
    isYinYangStarting = false
end

-- Network event handlers
Network.Fired("MutationEvent_Start", function(eventId: string, startTime: number, endTime: number)
    isEventActive = true
    currentEventId = eventId
    _eventStartTime = startTime
    eventEndTime = endTime
    
    if eventId == "YinYang" then
        task.spawn(startYinYangEvent)
        task.spawn(startGrassAnimation)
    end
    
    updateEventGuis()
end)

Network.Fired("MutationEvent_End", function(eventId: string)
    if eventId == "YinYang" then
        task.spawn(endYinYangEvent)
        task.spawn(stopGrassAnimation)
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
    if active and eventId == "YinYang" then
        task.spawn(startYinYangEvent)
        task.spawn(startGrassAnimation)
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
    
    -- Initialize with default YinYang display
    local eventData = Directory.MutationEvents["YinYang"]
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
    Public API to check if YinYang event is currently active.
    
    @return boolean - Whether YinYang event is active
]]
function MutationEventCmds.IsYinYangActive(): boolean
    return isEventActive and currentEventId == "YinYang"
end

--[[
    Public API to get the current event status.
    
    @return boolean, string? - Whether any event is active and the event ID
]]
function MutationEventCmds.GetCurrentEvent(): (boolean, string?)
    return isEventActive, currentEventId
end

-- Grass color animation functions
local function animateGrassColors()
    local WHITE = Color3.new(1, 1, 1)
    local DARK_GRAY = Color3.fromRGB(34, 34, 34)
    
    while isEventActive do
        -- Check if Party event is active - if so, skip this cycle
        if isPartyEventActive then
            task.wait(1)
            continue
        end
        
        -- Tween to white
        for _, part in ipairs(grassParts) do
            if part and part.Parent then
                local tween = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Color = WHITE})
                tween:Play()
            end
        end
        
        -- Wait on white (0.5s tween + 3s stay)
        task.wait(3.5)
        
        if not isEventActive then break end
        
        -- Check again before tweening to black
        if isPartyEventActive then
            task.wait(1)
            continue
        end
        
        -- Tween to dark gray
        for _, part in ipairs(grassParts) do
            if part and part.Parent then
                local tween = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Color = DARK_GRAY})
                tween:Play()
            end
        end
        
        -- Wait on dark gray (0.5s tween + 3s stay)
        task.wait(3.5)
    end
end

startGrassAnimation = function()
    -- Don't start if Party event is active
    if isPartyEventActive then
        return
    end
    
    -- Stop any existing animation
    stopGrassAnimation()
    
    -- Start new animation thread
    grassAnimationThread = task.spawn(animateGrassColors)
end

stopGrassAnimation = function()
    -- Cancel animation thread
    if grassAnimationThread then
        task.cancel(grassAnimationThread)
        grassAnimationThread = nil
    end
    
    -- Restore original colors
    for _, part in ipairs(grassParts) do
        if part and part.Parent then
            local originalColor = part:GetAttribute("OriginalColor")
            if typeof(originalColor) == "Color3" then
                part.Color = originalColor
            end
        end
    end
end

-- Setup TagHook to listen for Grass parts
TagHook("Grass", function(inst: Instance)
    if inst and inst:IsA("BasePart") then
        local part = inst :: BasePart
        table.insert(grassParts, part)
    end
    
    -- Cleanup function
    return function()
        if inst:IsA("BasePart") then
            local index = table.find(grassParts, inst)
            if index then
                table.remove(grassParts, index)
            end
        end
    end
end)

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
