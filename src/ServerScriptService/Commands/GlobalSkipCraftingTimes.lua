--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local GLOBAL_SKIP_CRAFTING_TOPIC = "SleepyFish:GlobalSkipCraftingTimes"

local Command = {
	Name = "GlobalSkipCraftingTimes",
	Aliases = {"globalskipcrafting"},
	Permissions = {"Owner", "Developer"},
	Parameters = {} :: {CommandType.Parameter},

	Execute = function(player, args)
		local payload = {
			sender = player.UserId
		}

		pcall(function()
			MessagingService:PublishAsync(GLOBAL_SKIP_CRAFTING_TOPIC, payload)
		end)
		
		print(`[GlobalSkipCraftingTimes] Published global skip request`)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

