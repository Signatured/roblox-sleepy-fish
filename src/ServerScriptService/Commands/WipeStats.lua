--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local Saving = require(ServerScriptService.Library.Saving)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local Command = {
	Name = "WipeStats",
	Aliases = {"clearstats"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]

		for _, targetPlayer in ipairs(targetPlayers) do			
			local saveData = Saving.Get(targetPlayer)

			if saveData then
				for k, v in pairs(saveData) do
					saveData[k] = nil
				end
            end

			targetPlayer:Kick("Stats wiped. Please rejoin.")
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 