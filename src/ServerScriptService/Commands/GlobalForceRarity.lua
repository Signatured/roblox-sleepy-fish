--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local FORCE_RARITY_TOPIC = "SleepyFish:ForceRarity"

local Command = {
	Name = "GlobalForceRarity",
	Aliases = {"globalforce", "gfr"},
	Permissions = {"Owner", "Developer"},
	Parameters = {
		{Type = "String", Name = "RarityId"},
		{Type = "String", Name = "Type", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local rarityId = args[1]
		local fishType = args[2]
		if typeof(rarityId) ~= "string" or #rarityId == 0 then return end
		pcall(function()
			MessagingService:PublishAsync(FORCE_RARITY_TOPIC, { rarityId = rarityId, fishType = fishType, sender = player.UserId })
		end)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}


