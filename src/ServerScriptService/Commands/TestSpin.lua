--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local Saving = require(ServerScriptService.Library.Saving)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local AdminPanel = require(ServerScriptService.Game.Library.AdminPanel)

local Command = {
	Name = "TestSpin",
	Aliases = {"testspin"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		AdminPanel.ExecuteCommand(player, "Fling", args[1][1])
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 