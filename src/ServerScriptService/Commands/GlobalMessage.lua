--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local TOPIC = "SleepyFish:AdminGlobalMessage"

local Command = {
	Name = "GlobalMessage",
	Aliases = {"globalmessage", "gmsg", "globalmsg"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "String", Name = "Message"},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local message = args[1]
		if typeof(message) ~= "string" or #message == 0 then return end

		local payload = {
			userId = player.UserId,
			text = message,
		}

		pcall(function()
			MessagingService:PublishAsync(TOPIC, payload)
		end)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}


