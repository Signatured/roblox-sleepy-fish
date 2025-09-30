--!strict

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local BanDataStore = DataStoreService:GetDataStore("PlayerBans")

local Command = {
	Name = "BanId",
	Aliases = {"banid"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "Number", Name = "UserId"},
		{Type = "String", Name = "Reason"},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local userId = args[1] :: number
		local reason = args[2] :: string
		
		if not userId or userId <= 0 then
			warn("[BanId Command] Invalid UserId provided")
			return
		end
		
		if not reason or reason == "" then
			reason = "No reason provided"
		end
		
		-- Don't allow banning yourself
		if userId == player.UserId then
			warn("[BanId Command] Cannot ban yourself")
			return
		end
		
		-- Store ban information in DataStore
		local banData = {
			banned = true,
			reason = reason,
			bannedBy = player.Name,
			bannedById = player.UserId,
			banTime = os.time(),
			banDate = os.date("%Y-%m-%d %H:%M:%S")
		}
		
		local success, errorMessage = pcall(function()
			BanDataStore:SetAsync("user_" .. userId, banData)
		end)
		
		if success then
			print(`[BanId Command] {player.Name} banned user ID {userId} for: {reason}`)
			
			-- Check if the player is currently in the game and kick them
			local targetPlayer = Players:GetPlayerByUserId(userId)
			if targetPlayer then
				local kickMessage = "You have been banned from this game.\n\n" ..
					"Banned by: " .. player.Name .. "\n" ..
					"Reason: " .. reason .. "\n" ..
					"Date: " .. banData.banDate .. "\n\n" ..
					"If you believe this ban was issued in error, please contact the game administrators."
				targetPlayer:Kick(kickMessage)
				print(`[BanId Command] Also kicked {targetPlayer.Name} who was online`)
			else
				print(`[BanId Command] User ID {userId} is not currently online`)
			end
		else
			warn(`[BanId Command] Failed to ban user ID {userId}: {errorMessage}`)
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}






