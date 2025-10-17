--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local FORCE_RARITY_TOPIC = "SleepyFish:ForceRarity"

local Command = {
	Name = "GlobalForceRarity",
	Aliases = {"globalforce", "gfr"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "String", Name = "RarityId"},
		{Type = "String", Name = "Type", Optional = true},
		{Type = "String", Name = "Mutation", Optional = true},
		{Type = "String", Name = "Traits", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local rarityId = args[1]
		local fishType = args[2]
		local mutation = args[3]
		local traitsString = args[4]
		
		if typeof(rarityId) ~= "string" or #rarityId == 0 then return end
		
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
					warn("[GlobalForceRarity] Invalid trait:", trimmedTraitId)
				end
			end
			-- If valid traits were added, set them
			if next(tempTraits) ~= nil then
				traits = tempTraits
			end
		end

		local payload = {
			rarityId = rarityId,
			fishType = fishType,
			mutation = mutation,
			traits = traits,
			sender = player.UserId
		}
		
		pcall(function()
			MessagingService:PublishAsync(FORCE_RARITY_TOPIC, payload)
		end)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}


