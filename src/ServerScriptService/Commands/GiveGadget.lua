--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local GadgetManager = require(ServerScriptService.Game.Library.Gadgets)

local Command = {
	Name = "GiveGadget",
	Aliases = {"gg", "givegadget"},
	Permissions = {"Admin", "Owner", "Tester", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
		{Type = "String", Name = "GadgetId"},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]
        local gadgetId = args[2]

		for _, targetPlayer in ipairs(targetPlayers) do
			GadgetManager.GiveAndInventory(targetPlayer, gadgetId:gsub("_", " "))
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 