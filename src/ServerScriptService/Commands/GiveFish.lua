--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.GameLibrary.Types.Commands)
local Fish = require(ServerScriptService.Game.GameServerLibrary.Fish)
local Assert = require(ReplicatedStorage.Library.Assert)

local Command = {
	Name = "Givefish",
	Aliases = {"gf", "givefish"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
		{Type = "String", Name = "FishId"},
        {Type = "String", Name = "Type", Optional = true},
        {Type = "String", Name = "Shiny", Optional = true},
        {Type = "Number", Name = "Level", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player, args)
        print(args)
		local targetPlayers = args[1]
        local fishId = args[2]
        local type = args[3] or "Normal"
        local shiny = args[4] or false
        local level = args[5] or 1

        if shiny == "true" then
            shiny = true
        elseif shiny == "false" then
            shiny = false
        end

        Assert.Boolean(shiny)

		for _, targetPlayer in ipairs(targetPlayers) do
			Fish.Give(targetPlayer, {
                FishId = fishId,
                Type = type,
                Shiny = shiny,
                Level = level
            })
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 