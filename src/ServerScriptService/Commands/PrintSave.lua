--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local Saving = require(ServerScriptService.Library.Saving)
local CommandType = require(ReplicatedStorage.Game.GameLibrary.Types.Commands)

local Command = {
	Name = "PrintSave",
	Aliases = {"printsave"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]

		for _, targetPlayer in ipairs(targetPlayers) do			
			local saveData = Saving.Get(targetPlayer)
			if saveData then
				print(saveData)
            end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 