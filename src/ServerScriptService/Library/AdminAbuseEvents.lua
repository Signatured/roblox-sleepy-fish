--!strict

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local FFlags = require(ServerScriptService.Library.FFlags)
local Network = require(ServerScriptService.Library.Network)
local Signal = require(game.ReplicatedStorage.Library.Signal)
local AdminAbuseEventsDirectory = require(game.ReplicatedStorage.Game.Library.Directory.AdminAbuseEvents)
local AdminAbuseEventsTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminAbuseEvents)

local module = {}

type ActiveEvent = {
	Id: string,
	StartTime: number,
	LastHeartbeat: number,
	HeartbeatConnection: RBXScriptConnection?,
	LocalOverride: boolean, -- true if started via command, ignores FFlag
	ServerModule: AdminAbuseEventsTypes.EventModule?,
}

local activeEvents: { [string]: ActiveEvent } = {}

-- Fire a network event to all clients for a specific event
function module.Fire(eventId: string, eventName: string, data: any?)
	if not activeEvents[eventId] then
		warn("[AdminAbuseEvents] Cannot fire network event for inactive event:", eventId)
		return
	end
	
	Network.FireAll("AdminAbuseEvent_Network", eventId, eventName, data)
end

-- Fire a network event to a specific player for a specific event
function module.FirePlayer(player: Player, eventId: string, eventName: string, data: any?)
	if not activeEvents[eventId] then
		warn("[AdminAbuseEvents] Cannot fire network event for inactive event:", eventId)
		return
	end
	
	Network.Fire(player, "AdminAbuseEvent_Network", eventId, eventName, data)
end

-- Get server module for an event
local function getServerModule(eventId: string, eventData: AdminAbuseEventsTypes.dir_schema): AdminAbuseEventsTypes.EventModule?
	local success, serverModule = pcall(function()
		local modulesFolder = ServerScriptService:FindFirstChild("Game")
		if modulesFolder then
			modulesFolder = modulesFolder:FindFirstChild("Modules")
		end
		if modulesFolder then
			modulesFolder = modulesFolder:FindFirstChild("AdminAbuseEvents")
		end
		if modulesFolder then
			local moduleScript = modulesFolder:FindFirstChild(eventData.ServerModule)
			if moduleScript and moduleScript:IsA("ModuleScript") then
				return require(moduleScript)::any
			end
		end
		return nil
	end)
	
	if success and serverModule then
		return serverModule
	else
		warn("[AdminAbuseEvents] Failed to load server module:", eventData.ServerModule)
		return nil
	end
end

-- Start an admin abuse event
function module.Start(eventId: string, localOverride: boolean?): boolean
	-- Check if event exists in directory
	local eventData = AdminAbuseEventsDirectory[eventId]
	if not eventData then
		warn("[AdminAbuseEvents] Event not found:", eventId)
		return false
	end

	-- Check if already running
	if activeEvents[eventId] then
		warn("[AdminAbuseEvents] Event already running:", eventId)
		return false
	end

	-- Load server module
	local serverModule = getServerModule(eventId, eventData)
	if not serverModule then
		warn("[AdminAbuseEvents] No server module or functions found for:", eventId)
		return false
	end

	local startTime = workspace:GetServerTimeNow()

	-- Create active event entry
	local activeEvent: ActiveEvent = {
		Id = eventId,
		StartTime = startTime,
		LastHeartbeat = startTime,
		HeartbeatConnection = nil,
		LocalOverride = localOverride == true,
		ServerModule = serverModule,
	}
	activeEvents[eventId] = activeEvent

	-- Call server OnStart
	local success, err = pcall(function()
		serverModule.OnStart()
	end)
	if not success then
		warn("[AdminAbuseEvents] Server OnStart failed for", eventId, ":", err)
	end

	-- Set up Heartbeat loop
	activeEvent.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		local currentTime = workspace:GetServerTimeNow()
		local elapsedTime = currentTime - activeEvent.StartTime
		local delta = currentTime - activeEvent.LastHeartbeat
		activeEvent.LastHeartbeat = currentTime

		-- Call server Heartbeat
		if serverModule.Heartbeat then
			local heartbeatSuccess, heartbeatErr = pcall(function()
				serverModule.Heartbeat(delta, elapsedTime)
			end)
			if not heartbeatSuccess then
				warn("[AdminAbuseEvents] Server Heartbeat failed for", eventId, ":", heartbeatErr)
			end
		end
	end)

	-- Notify all clients to start
	Network.FireAll("AdminAbuseEvent_Start", eventId, startTime)

	print("[AdminAbuseEvents] Started event:", eventId, "at", startTime)
	return true
end

-- Stop an admin abuse event
function module.Stop(eventId: string): boolean
	local activeEvent = activeEvents[eventId]
	if not activeEvent then
		warn("[AdminAbuseEvents] Event not running:", eventId)
		return false
	end

	-- Disconnect Heartbeat
	if activeEvent.HeartbeatConnection then
		activeEvent.HeartbeatConnection:Disconnect()
		activeEvent.HeartbeatConnection = nil
	end

	-- Call server OnStop
	if activeEvent.ServerModule then
		local success, err = pcall(function()
			activeEvent.ServerModule.OnStop()
		end)
		if not success then
			warn("[AdminAbuseEvents] Server OnStop failed for", eventId, ":", err)
		end
	end

	-- Remove from active events
	activeEvents[eventId] = nil

	-- Notify all clients to stop
	Network.FireAll("AdminAbuseEvent_Stop", eventId)

	print("[AdminAbuseEvents] Stopped event:", eventId)
	return true
end

-- Get active events (for newly joined players)
function module.GetActiveEvents(): { [string]: number }
	local result: { [string]: number } = {}
	for eventId, activeEvent in pairs(activeEvents) do
		result[eventId] = activeEvent.StartTime
	end
	return result
end

-- Check if an event is active
function module.IsActive(eventId: string): boolean
	return activeEvents[eventId] ~= nil
end

-- Handle FFlag changes
local function handleFFlagChange(eventId: string, enabled: boolean)
	local activeEvent = activeEvents[eventId]

	-- If event has local override, don't respond to FFlag changes
	if activeEvent and activeEvent.LocalOverride then
		return
	end

	if enabled then
		-- Start event if FFlag is enabled and not already running
		if not activeEvent then
			module.Start(eventId, false)
		end
	else
		-- Stop event if FFlag is disabled and running (but not local override)
		if activeEvent and not activeEvent.LocalOverride then
			module.Stop(eventId)
		end
	end
end

-- Initialize: Check all FFlags on boot and connect to changes
local function initialize()
	-- Wait for FFlags to load
	while not FFlags.IsLoaded() do
		task.wait(0.1)
	end

	-- Check all events in directory and start if their FFlag is enabled
	for eventId, _ in pairs(AdminAbuseEventsDirectory) do
		local flagKey = "AdminAbuseEvent_" .. eventId
		if FFlags.Keys[flagKey] then
			local enabled = FFlags.GetBoolean(FFlags.Keys[flagKey])
			if enabled then
				module.Start(eventId, false)
			end
		end
	end

	-- Listen for FFlag changes
	-- Note: FFlags collapse to nil when set to default, so we must check all flags on each change
	Signal.Fired("FFlags Changed"):Connect(function(_changedData: { [string]: any })
		-- Check all AdminAbuseEvent flags, not just the changed ones
		for eventId, _ in pairs(AdminAbuseEventsDirectory) do
			local flagKey = "AdminAbuseEvent_" .. eventId
			if FFlags.Keys[flagKey] then
				local enabled = FFlags.GetBoolean(FFlags.Keys[flagKey])
				handleFFlagChange(eventId, enabled)
			end
		end
	end)
end

-- Handle player joining - send them active events
Signal.Fired("Player Loaded"):Connect(function(player: Player)
	local activeEventsData = module.GetActiveEvents()
	for eventId, startTime in pairs(activeEventsData) do
		Network.Fire(player, "AdminAbuseEvent_Start", eventId, startTime)
	end
end)

-- Initialize on server start
task.spawn(initialize)

return module

