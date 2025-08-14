--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Network = require(ServerScriptService.Library.Network)

local Command = {
    Name = "FFlags",
    Aliases = {"fflags"},
    Permissions = {"Admin", "Owner", "Developer"},
    Parameters = {} :: {CommandType.Parameter},

    Execute = function(player: Player, _args: {any})
        -- Opens the client FFlags UI
        Network.Fire(player, "Open FFlags")
    end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}


