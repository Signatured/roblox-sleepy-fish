--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local GLOBAL_FORCE_GIVE_TOPIC = "SleepyFish:GlobalForceGive"

local Command = {
	Name = "GlobalForceGive",
	Aliases = {"globalforcegive", "gfg", "globalgive"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "String", Name = "FishId"},
		{Type = "String", Name = "Type", Optional = true},
		{Type = "String", Name = "Mutation", Optional = true},
		{Type = "String", Name = "Traits", Optional = true},
		{Type = "Number", Name = "Level", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local fishId = args[1]
		local fishType = args[2] or "Normal"
		local mutation = args[3]
		local traitsString = args[4]
		local level = args[5] or 1

		if typeof(fishId) ~= "string" or #fishId == 0 then return end
		
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
					warn("[GlobalForceGive] Invalid trait:", trimmedTraitId)
				end
			end
			-- If valid traits were added, set them
			if next(tempTraits) ~= nil then
				traits = tempTraits
			end
		end

		local payload = {
			fishId = fishId,
			fishType = fishType,
			mutation = mutation,
			traits = traits,
			level = level,
			sender = player.UserId
		}

		pcall(function()
			MessagingService:PublishAsync(GLOBAL_FORCE_GIVE_TOPIC, payload)
		end)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}
