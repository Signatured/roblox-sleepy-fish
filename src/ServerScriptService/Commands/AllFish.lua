--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Fish = require(ServerScriptService.Game.Library.Fish)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local ExistCount = require(ServerScriptService.Game.Library.ExistCount)
local Index = require(ServerScriptService.Game.Library.Index)

local Command = {
	Name = "AllFish",
	Aliases = {"allfish", "af"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]

		for _, targetPlayer in ipairs(targetPlayers) do
			-- Iterate through all fish in the Directory
			for fishId, fishSchema in pairs(Directory.Fish) do
				local data = Fish.Give(targetPlayer, {
					FishId = fishId,
					Type = "Normal",
					Mutation = "YinYang",
					Traits = nil,
					Shiny = false,
					Level = 1
				})

				if data then
					ExistCount.IncrementCount(data.FishId, data.Type)
					Index.Add(player, data.FishId, data.Type, data.Mutation)
				end
			end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

