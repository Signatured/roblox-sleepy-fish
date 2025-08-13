--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.GameLibrary.Types.Commands)

local Command = {
	Name = "Private",
	Aliases = {"private"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]
        local placeId = game.PlaceId
        local ReservedServerCode = TeleportService:ReserveServer(placeId)

		for _, targetPlayer in ipairs(targetPlayers) do			
			TeleportService:TeleportToPrivateServer(
			placeId,
			ReservedServerCode,
			{player},
			nil,
			nil,
			nil
		)
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 