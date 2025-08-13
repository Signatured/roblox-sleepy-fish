--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerPlot = require(ServerScriptService.Plot.ServerPlot)
local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.GameLibrary.Types.Commands)
local Assert = require(ReplicatedStorage.Library.Assert)

local Command = { 
	Name = "GiveMoney",
	Aliases = {"givemoney", "money", "gm"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
		{Type = "Number", Name = "Amount"},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]
		local amount = args[2]

		for _, targetPlayer in ipairs(targetPlayers) do
			local plot = ServerPlot.GetByPlayer(targetPlayer)

			if plot then
				plot:AddMoney(amount)
				print("Gave money to", targetPlayer.Name, amount)
			end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 