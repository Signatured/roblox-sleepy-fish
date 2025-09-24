--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local GLOBAL_SLEEP_TOPIC = "SleepyFish:GlobalSleep"

local Command = {
	Name = "GlobalSleep",
	Aliases = {"globalsleep", "gsleep", "sleepall"},
	Permissions = {"Owner", "Developer"},
	Parameters = {
		{Type = "Number", Name = "Duration", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local duration = args[1] or 60
		
		if typeof(duration) ~= "number" or duration <= 0 then
			duration = 60
		end

		local payload = {
			duration = duration,
			sender = player.UserId
		}

		pcall(function()
			MessagingService:PublishAsync(GLOBAL_SLEEP_TOPIC, payload)
		end)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}
