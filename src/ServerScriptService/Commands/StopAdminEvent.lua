--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local AdminAbuseEvents = require(ServerScriptService.Game.Library.AdminAbuseEvents)
local AdminAbuseEventsDirectory = require(ReplicatedStorage.Game.Library.Directory.AdminAbuseEvents)

local Command = {
	Name = "StopAdminEvent",
	Aliases = {"sae", "stopadminevent"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "String", Name = "EventId"}
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local eventId = args[1]

		-- Check if event exists
		if not AdminAbuseEventsDirectory[eventId] then
			return "Event '" .. eventId .. "' does not exist."
		end

		-- Stop the event
		local success = AdminAbuseEvents.Stop(eventId)
		
		if success then
			return "Stopped admin abuse event: " .. eventId
		else
			return "Failed to stop event (may not be running): " .. eventId
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

