--!strict

local RunService = game:GetService("RunService")

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local AdminAbuseEventsDirectory = require(game.ReplicatedStorage.Game.Library.Directory.AdminAbuseEvents)

local module = {}

type ActiveEvent = {
	Id: string,
	StartTime: number,
	RenderSteppedConnection: RBXScriptConnection?,
}

local activeEvents: { [string]: ActiveEvent } = {}

-- Start an admin abuse event on client
local function startEvent(eventId: string, startTime: number)
	-- Check if event exists in directory
	local eventData = AdminAbuseEventsDirectory[eventId]
	if not eventData then
		warn("[AdminAbuseEventCmds] Event not found:", eventId)
		return
	end

	-- Check if already running
	if activeEvents[eventId] then
		warn("[AdminAbuseEventCmds] Event already running:", eventId)
		return
	end

	-- Create active event entry
	local activeEvent: ActiveEvent = {
		Id = eventId,
		StartTime = startTime,
		RenderSteppedConnection = nil,
	}
	activeEvents[eventId] = activeEvent

	-- Call client OnStart
	local success, err = pcall(function()
		eventData.ClientFunctions.OnStart()
	end)
	if not success then
		warn("[AdminAbuseEventCmds] Client OnStart failed for", eventId, ":", err)
	end

	-- Set up RenderStepped loop with synced time
	local lastFrameTime = workspace:GetServerTimeNow()
	activeEvent.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		local currentTime = workspace:GetServerTimeNow()
		local elapsedTime = currentTime - activeEvent.StartTime
		local delta = currentTime - lastFrameTime
		lastFrameTime = currentTime

		-- Call client RenderStepped
		local renderSuccess, renderErr = pcall(function()
			eventData.ClientFunctions.RenderStepped(delta, elapsedTime)
		end)
		if not renderSuccess then
			warn("[AdminAbuseEventCmds] Client RenderStepped failed for", eventId, ":", renderErr)
		end
	end)

	print("[AdminAbuseEventCmds] Started event:", eventId, "at", startTime)
end

-- Stop an admin abuse event on client
local function stopEvent(eventId: string)
	local activeEvent = activeEvents[eventId]
	if not activeEvent then
		warn("[AdminAbuseEventCmds] Event not running:", eventId)
		return
	end

	-- Disconnect RenderStepped
	if activeEvent.RenderSteppedConnection then
		activeEvent.RenderSteppedConnection:Disconnect()
		activeEvent.RenderSteppedConnection = nil
	end

	-- Call client OnStop
	local eventData = AdminAbuseEventsDirectory[eventId]
	if eventData then
		local success, err = pcall(function()
			eventData.ClientFunctions.OnStop()
		end)
		if not success then
			warn("[AdminAbuseEventCmds] Client OnStop failed for", eventId, ":", err)
		end
	end

	-- Remove from active events
	activeEvents[eventId] = nil

	print("[AdminAbuseEventCmds] Stopped event:", eventId)
end

-- Check if an event is active
function module.IsActive(eventId: string): boolean
	return activeEvents[eventId] ~= nil
end

-- Get all active event IDs
function module.GetActiveEvents(): { string }
	local result: { string } = {}
	for eventId, _ in pairs(activeEvents) do
		table.insert(result, eventId)
	end
	return result
end

-- Listen for server network events
Network.Fired("AdminAbuseEvent_Start", function(eventId: string, startTime: number)
	startEvent(eventId, startTime)
end)

Network.Fired("AdminAbuseEvent_Stop", function(eventId: string)
	stopEvent(eventId)
end)

return module

