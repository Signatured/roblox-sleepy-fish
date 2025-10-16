--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local AdminAbuseEvents = require(ServerScriptService.Game.Library.AdminAbuseEvents)
local AdminAbuseEventsDirectory = require(ReplicatedStorage.Game.Library.Directory.AdminAbuseEvents)

local Command = {
	Name = "LocalAdminEvent",
	Aliases = {"lae", "localadminevent", "startadminevent"},
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

		-- Start the event with local override (bypasses FFlag)
		local success = AdminAbuseEvents.Start(eventId, true)
		
		if success then
			return "Started admin abuse event: " .. eventId
		else
			return "Failed to start event (may already be running): " .. eventId
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

