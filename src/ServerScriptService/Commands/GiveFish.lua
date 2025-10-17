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
        {Type = "String", Name = "Traits", Optional = true},
        {Type = "Number", Name = "Level", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]
        local fishId = args[2]
        local type = args[3] or "Normal"
        local mutation = args[4]
        local traitsString = args[5]
        local level = args[6] or 1

        -- Treat "nil" string as nil
        if mutation == "nil" then
            mutation = nil
        end
        if traitsString == "nil" then
            traitsString = nil
        end

        -- Validate mutation if provided by checking if it exists in the Mutations directory
        if mutation and not Directory.Mutations[mutation] then
            mutation = nil
        end

        -- Parse and validate traits if provided
        local traits: {[string]: boolean}? = nil
        if traitsString and traitsString ~= "" then
            local tempTraits: {[string]: boolean} = {}
            -- Split by comma
            for traitId in string.gmatch(traitsString, "[^,]+") do
                -- Trim whitespace
                local trimmedTraitId = string.match(traitId, "^%s*(.-)%s*$")
                -- Validate trait exists in Directory
                if trimmedTraitId and Directory.Traits[trimmedTraitId] then
                    tempTraits[trimmedTraitId] = true
                elseif trimmedTraitId then
                    warn("[GiveFish] Invalid trait:", trimmedTraitId)
                end
            end
            -- If valid traits were added, set them
            if next(tempTraits) ~= nil then
                traits = tempTraits
            end
        end

		for _, targetPlayer in ipairs(targetPlayers) do
			local data = Fish.Give(targetPlayer, {
                FishId = fishId,
                Type = type,
                Mutation = mutation,
                Traits = traits,
                Shiny = false,
                Level = level
            })

            if data then
                ExistCount.IncrementCount(data.FishId, data.Type)
                if data.Mutation then
                    ExistCount.IncrementMutationCount(data.FishId, data.Mutation)
                end
                Index.Add(player, data.FishId, data.Type, data.Mutation)
            end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 