--!strict

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local BanDataStore = DataStoreService:GetDataStore("PlayerBans")

local Command = {
	Name = "CheckBan",
	Aliases = {"checkban", "bancheck"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "Number", Name = "UserId"},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local userId = args[1] :: number
		
		if not userId or userId <= 0 then
			warn("[CheckBan Command] Invalid UserId provided")
			return
		end
		
		-- Check ban status in DataStore
		local success, banData = pcall(function()
			return BanDataStore:GetAsync("user_" .. userId)
		end)
		
		if success then
			if banData and banData.banned then
				print(`[CheckBan Command] User ID {userId} is BANNED:\n` ..
					`- Banned by: {banData.bannedBy} (ID: {banData.bannedById})\n` ..
					`- Reason: {banData.reason}\n` ..
					`- Date: {banData.banDate}`)
			else
				print(`[CheckBan Command] User ID {userId} is NOT banned`)
			end
		else
			warn(`[CheckBan Command] Failed to check ban status for user ID {userId}: {banData}`)
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}
