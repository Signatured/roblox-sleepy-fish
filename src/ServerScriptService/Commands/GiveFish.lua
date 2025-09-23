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
	Name = "Givefish",
	Aliases = {"gf", "givefish"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
		{Type = "String", Name = "FishId"},
        {Type = "String", Name = "Type", Optional = true},
        {Type = "String", Name = "Mutation", Optional = true},
        {Type = "Number", Name = "Level", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]
        local fishId = args[2]
        local type = args[3] or "Normal"
        local mutation = args[4]
        local level = args[5] or 1

        -- Validate mutation if provided by checking if it exists in the Mutations directory
        if mutation and not Directory.Mutations[mutation] then
            mutation = nil
        end

		for _, targetPlayer in ipairs(targetPlayers) do
			local data = Fish.Give(targetPlayer, {
                FishId = fishId,
                Type = type,
                Mutation = mutation,
                Shiny = false,
                Level = level
            })

            if data then
                ExistCount.IncrementCount(data.FishId, data.Type)
                if data.Mutation == "Bloodfish" then
                    ExistCount.IncrementBloodfishCount(data.FishId)
                end
                Index.Add(player, data.FishId, data.Type, data.Mutation)
            end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 