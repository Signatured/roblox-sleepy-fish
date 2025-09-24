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
	Permissions = {"Owner", "Developer"},
	Parameters = {
		{Type = "String", Name = "FishId"},
		{Type = "String", Name = "Type", Optional = true},
		{Type = "String", Name = "Mutation", Optional = true},
		{Type = "Number", Name = "Level", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local fishId = args[1]
		local fishType = args[2] or "Normal"
		local mutation = args[3]
		local level = args[4] or 1

		if typeof(fishId) ~= "string" or #fishId == 0 then return end
		
		-- Validate mutation if provided by checking if it exists in the Mutations directory
		if mutation and not Directory.Mutations[mutation] then
			mutation = nil
		end

		local payload = {
			fishId = fishId,
			fishType = fishType,
			mutation = mutation,
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
