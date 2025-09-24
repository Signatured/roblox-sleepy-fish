--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local AdminPanel = require(ServerScriptService.Game.Library.AdminPanel)

local Command = {
	Name = "Test",
	Aliases = {"test"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		AdminPanel.ExecuteCommand(player, "Jumpscare", args[1][1])
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 