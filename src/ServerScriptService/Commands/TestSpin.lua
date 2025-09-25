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
		-- Example: Execute as console (nil executor) with target player
		if args[1] and args[1][1] then
			AdminPanel.ExecuteConsoleCommand("Ragdoll", args[1][1])
		else
			-- Fallback: Execute as player
			AdminPanel.ExecuteCommand(player, "Ragdoll", args[1] and args[1][1] or nil)
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 