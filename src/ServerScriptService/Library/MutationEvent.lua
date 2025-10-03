--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Network = require(ServerScriptService.Library.Network)
local _Directory = require(ReplicatedStorage.Game.Library.Directory)
local MutationEventDirectory = require(ReplicatedStorage.Game.Library.Directory.MutationEvents)

local MutationEvent = {}

-- Configuration
local CURRENT_EVENT_ID = "Galaxy" -- Directory ID of the current mutation event
local EST_OFFSET = -5 * 3600 -- EST is UTC-5 (in seconds)

-- Debug Configuration
local DEBUG_MODE = false -- Set to true to enable debug timing
local DEBUG_START_DELAY = -5 -- Seconds after server boot to start first event in debug mode

-- State
local currentEvent: any = nil
local eventStartTime: number? = nil
local eventEndTime: number? = nil
local nextEventTime: number? = nil

local function getESTTime(): number
    return DateTime.now().UnixTimestamp + EST_OFFSET
end

local serverBootTime = getESTTime() -- Track when server started

local function calculateNextEventTime(): number
    local eventData = MutationEventDirectory[CURRENT_EVENT_ID]
    if not eventData then
        warn("[MutationEvent] Event data not found for:", CURRENT_EVENT_ID)
        return 0
    end

    -- Debug mode: start event shortly after server boot
    if DEBUG_MODE then
        local debugStartTime = serverBootTime + DEBUG_START_DELAY
        local now = getESTTime()
        
        if now < debugStartTime then
            -- First event hasn't started yet
            return debugStartTime
        else
            -- Calculate subsequent events based on normal interval from debug start
            local interval = eventData.Interval
            local nextTime = debugStartTime
            while nextTime <= now do
                nextTime = nextTime + interval
            end
            return nextTime
        end
    end

    -- Normal mode: events start at 11am EST
    local now = getESTTime()
    local interval = eventData.Interval
    
    -- Events start at 11am EST (11 * 3600 seconds from midnight)
    local elevenAMToday = math.floor(now / 86400) * 86400 + 11 * 3600
    
    -- If it's past 11am today, start from 11am today, otherwise start from 11am yesterday
    local baseTime = now >= elevenAMToday and elevenAMToday or (elevenAMToday - 86400)
    
    -- Find the next event time based on interval
    local nextTime = baseTime
    while nextTime <= now do
        nextTime = nextTime + interval
    end
    
    return nextTime
end

local function updateEventState()
    local eventData = MutationEventDirectory[CURRENT_EVENT_ID]
    if not eventData then return end

    local now = getESTTime()
    
    -- Initialize next event time if not set
    if not nextEventTime then
        nextEventTime = calculateNextEventTime()
    end
    
    -- Check if we should start the event
    if now >= (nextEventTime :: number) and not currentEvent then
        -- Start event
        currentEvent = eventData
        eventStartTime = now
        eventEndTime = now + eventData.Duration
        
        -- Calculate next event after this one
        nextEventTime = (nextEventTime :: number) + eventData.Interval
        
        -- Notify all clients to start the event

        for _, player in ipairs(Players:GetPlayers()) do
            if player:GetAttribute("Loaded") then
                Network.Fire(player, "MutationEvent_Start", CURRENT_EVENT_ID, eventStartTime, eventEndTime)
            end
        end
        
    -- Check if we should end the event
    elseif currentEvent and now >= (eventEndTime :: number) then
        -- End event
        Network.FireAll("MutationEvent_End", CURRENT_EVENT_ID)
        
        currentEvent = nil
        eventStartTime = nil
        eventEndTime = nil
    end
end

function MutationEvent.GetCurrentStatus(): (boolean, string?, number?, number?, number?)
    local isActive = currentEvent ~= nil
    local eventId = isActive and CURRENT_EVENT_ID or nil
    local startTime = eventStartTime
    local endTime = eventEndTime
    local nextTime = nextEventTime
    
    return isActive, eventId, startTime, endTime, nextTime
end

-- Network handlers
Network.Fired("MutationEvent_GetStatus", function(player: Player)
    local isActive, eventId, startTime, endTime, nextTime = MutationEvent.GetCurrentStatus()
    Network.Fire(player, "MutationEvent_Status", isActive, eventId, startTime, endTime, nextTime)
end)

-- Main update loop
RunService.Heartbeat:Connect(function()
    updateEventState()
end)

-- Initialize
task.spawn(function()
    -- Wait for directory to load
    task.wait(1)
    
    local eventData = MutationEventDirectory[CURRENT_EVENT_ID]
    if not eventData then 
        nextEventTime = calculateNextEventTime()
        return 
    end
    
    local now = getESTTime()
    
    -- Check if we should currently be in an active event
    if DEBUG_MODE then
        local debugStartTime = serverBootTime + DEBUG_START_DELAY
        local interval = eventData.Interval
        local duration = eventData.Duration
        
        -- Find the most recent event start time
        local recentEventStart = debugStartTime
        while recentEventStart + interval <= now do
            recentEventStart = recentEventStart + interval
        end
        
        -- Check if we're within the duration of this event
        if now >= recentEventStart and now < recentEventStart + duration then
            -- We're in an active event!
            currentEvent = eventData
            eventStartTime = recentEventStart
            eventEndTime = recentEventStart + duration
            nextEventTime = recentEventStart + interval
            
            -- Notify all clients to start the event
            for _, player in ipairs(Players:GetPlayers()) do
                if player:GetAttribute("Loaded") then
                    Network.Fire(player, "MutationEvent_Start", CURRENT_EVENT_ID, eventStartTime, eventEndTime)
                end
            end
        else
            -- No active event, calculate next one
            nextEventTime = recentEventStart + interval
        end
    else
        -- Normal mode: check if we're in an active event window
        local interval = eventData.Interval
        local duration = eventData.Duration
        
        -- Events start at 11am EST (11 * 3600 seconds from midnight)
        local elevenAMToday = math.floor(now / 86400) * 86400 + 11 * 3600
        
        -- If it's past 11am today, start from 11am today, otherwise start from 11am yesterday
        local baseTime = now >= elevenAMToday and elevenAMToday or (elevenAMToday - 86400)
        
        -- Find the most recent event start time
        local recentEventStart = baseTime
        while recentEventStart + interval <= now do
            recentEventStart = recentEventStart + interval
        end
        
        -- Check if we're within the duration of this event
        if now >= recentEventStart and now < recentEventStart + duration then
            -- We're in an active event!
            currentEvent = eventData
            eventStartTime = recentEventStart
            eventEndTime = recentEventStart + duration
            nextEventTime = recentEventStart + interval
            
            -- Notify all clients to start the event
            for _, player in ipairs(Players:GetPlayers()) do
                if player:GetAttribute("Loaded") then
                    Network.Fire(player, "MutationEvent_Start", CURRENT_EVENT_ID, eventStartTime, eventEndTime)
                end
            end
        else
            -- No active event, calculate next one
            nextEventTime = recentEventStart + interval
        end
    end
end)

return MutationEvent
