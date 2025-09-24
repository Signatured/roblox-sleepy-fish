--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local GLOBAL_FORCE_SPAWN_TOPIC = "SleepyFish:GlobalForceSpawn"

local Command = {
	Name = "GlobalForceSpawn",
	Aliases = {"globalforcespawn", "gfs", "globalspawn"},
	Permissions = {"Owner", "Developer"},
	Parameters = {
		{Type = "String", Name = "FishId"},
		{Type = "String", Name = "Type", Optional = true},
		{Type = "String", Name = "Mutation", Optional = true}
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local fishId = args[1]
		local fishType = args[2] or "Normal"
		local mutation = args[3]

		if typeof(fishId) ~= "string" or #fishId == 0 then return end
		
		-- Validate mutation if provided by checking if it exists in the Mutations directory
		if mutation and not Directory.Mutations[mutation] then
			mutation = nil
		end

		local payload = {
			fishId = fishId,
			fishType = fishType,
			mutation = mutation,
			sender = player.UserId
		}

		pcall(function()
			MessagingService:PublishAsync(GLOBAL_FORCE_SPAWN_TOPIC, payload)
		end)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}
