--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)
local AdminAbuseEventsDirectory = require(ReplicatedStorage.Game.Library.Directory.AdminAbuseEvents)
local AdminAbuseEventsTypes = require(ReplicatedStorage.Game.Library.Types.AdminAbuseEvents)

local module = {}

type ActiveEvent = {
	Id: string,
	StartTime: number,
	RenderSteppedConnection: RBXScriptConnection?,
	ClientModule: AdminAbuseEventsTypes.EventModule?,
	NetworkHandlers: { [string]: (data: any?) -> () },
}

local activeEvents: { [string]: ActiveEvent } = {}

-- Register a handler for network events from the server
function module.Fired(eventId: string, eventName: string, handler: (data: any?) -> ())
	local activeEvent = activeEvents[eventId]
	if not activeEvent then
		warn("[AdminAbuseEventCmds] Cannot register handler for inactive event:", eventId)
		return
	end
	
	if activeEvent.NetworkHandlers[eventName] then
		warn("[AdminAbuseEventCmds] Handler already registered for:", eventId, eventName)
		return
	end
	
	activeEvent.NetworkHandlers[eventName] = handler
end

-- Get client module for an event
local function getClientModule(eventId: string, eventData: AdminAbuseEventsTypes.dir_schema): AdminAbuseEventsTypes.EventModule?
	local success, clientModule = pcall(function()
		local modulesFolder = ReplicatedStorage:FindFirstChild("Game")
		if modulesFolder then
			modulesFolder = modulesFolder:FindFirstChild("Modules")
		end
		if modulesFolder then
			modulesFolder = modulesFolder:FindFirstChild("AdminAbuseEvents")
		end
		if modulesFolder then
			local moduleScript = modulesFolder:FindFirstChild(eventData.ClientModule)
			if moduleScript and moduleScript:IsA("ModuleScript") then
				return require(moduleScript)::any
			end
		end
		return nil
	end)
	
	if success and clientModule then
		return clientModule
	else
		warn("[AdminAbuseEventCmds] Failed to load client module:", eventData.ClientModule)
		return nil
	end
end

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
		return
	end

	-- Load client module
	local clientModule = getClientModule(eventId, eventData)
	if not clientModule then
		warn("[AdminAbuseEventCmds] No client module or functions found for:", eventId)
		return
	end

	-- Create active event entry
	local activeEvent: ActiveEvent = {
		Id = eventId,
		StartTime = startTime,
		RenderSteppedConnection = nil,
		ClientModule = clientModule,
		NetworkHandlers = {},
	}
	activeEvents[eventId] = activeEvent

	-- Call client OnStart
	local success, err = pcall(function()
		clientModule.OnStart()
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
		if clientModule.RenderStepped then
			local renderSuccess, renderErr = pcall(function()
				clientModule.RenderStepped(delta, elapsedTime)
			end)
			if not renderSuccess then
				warn("[AdminAbuseEventCmds] Client RenderStepped failed for", eventId, ":", renderErr)
			end
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
	if activeEvent.ClientModule then
		local success, err = pcall(function()
			activeEvent.ClientModule.OnStop()
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

-- Listen for custom network events from server
Network.Fired("AdminAbuseEvent_Network", function(eventId: string, eventName: string, data: any?)
	local activeEvent = activeEvents[eventId]
	if not activeEvent then
		return
	end
	
	local handler = activeEvent.NetworkHandlers[eventName]
	if handler then
		task.spawn(handler, data)
	end
end)

-- Request active events from server when module loads
task.defer(function()
	Network.Fire("AdminAbuseEvent_RequestActive")
end)

return module

