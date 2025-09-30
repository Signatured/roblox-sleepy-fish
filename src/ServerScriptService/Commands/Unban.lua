--!strict

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local BanDataStore = DataStoreService:GetDataStore("PlayerBans")

local Command = {
	Name = "Unban",
	Aliases = {"unban"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "Number", Name = "UserId"},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local userId = args[1] :: number
		
		if not userId or userId <= 0 then
			warn("[Unban Command] Invalid UserId provided")
			return
		end
		
		-- Remove ban data from DataStore
		local success, errorMessage = pcall(function()
			BanDataStore:RemoveAsync("user_" .. userId)
		end)
		
		if success then
			print(`[Unban Command] {player.Name} unbanned user ID: {userId}`)
		else
			warn(`[Unban Command] Failed to unban user ID {userId}: {errorMessage}`)
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}







