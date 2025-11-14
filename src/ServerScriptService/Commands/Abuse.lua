--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Network = require(ServerScriptService.Library.Network)

local Command = {
	Name = "Abuse",
	Aliases = {"abuse", "abusepanel"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		-- Open the abuse panel for the player
		Network.Fire(player, "AbusePanel_Open")
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

