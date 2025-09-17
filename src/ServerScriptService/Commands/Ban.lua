--!strict

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)

local BanDataStore = DataStoreService:GetDataStore("PlayerBans")

local Command = {
	Name = "Ban",
	Aliases = {"ban"},
	Permissions = {"Owner", "Developer"}, -- Only highest level admins can ban
	Parameters = {
		{Type = "Player", Name = "TargetPlayer"},
		{Type = "String", Name = "Reason"},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local targetPlayers = args[1] :: {Player}
		local reason = args[2] :: string
		
		if not targetPlayers or #targetPlayers == 0 then
			warn("[Ban Command] No target players provided")
			return
		end
		
		if not reason or reason == "" then
			reason = "No reason provided"
		end
		
		for _, targetPlayer in ipairs(targetPlayers) do
			-- Don't allow banning other admins/owners/developers
			if targetPlayer == player then
				warn("[Ban Command] Cannot ban yourself")
				continue
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
				BanDataStore:SetAsync("user_" .. targetPlayer.UserId, banData)
			end)
			
			if success then
				print(`[Ban Command] {player.Name} banned {targetPlayer.Name} (ID: {targetPlayer.UserId}) for: {reason}`)
				
				-- Kick the player with ban message
				local kickMessage = "You have been banned from this game.\n\n" ..
					"Banned by: " .. player.Name .. "\n" ..
					"Reason: " .. reason .. "\n" ..
					"Date: " .. banData.banDate .. "\n\n" ..
					"If you believe this ban was issued in error, please contact the game administrators."
				targetPlayer:Kick(kickMessage)
			else
				warn(`[Ban Command] Failed to ban {targetPlayer.Name}: {errorMessage}`)
			end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

-- Check for banned players when they join
Players.PlayerAdded:Connect(function(player: Player)
	-- Small delay to ensure player is fully loaded
	task.wait(0.1)
	
	local success, banData = pcall(function()
		return BanDataStore:GetAsync("user_" .. player.UserId)
	end)
	
	if success and banData and banData.banned then
		print(`[Ban System] Kicked banned player: {player.Name} (ID: {player.UserId})`)
		local kickMessage = "You are banned from this game.\n\n" ..
			"Banned by: " .. banData.bannedBy .. "\n" ..
			"Reason: " .. banData.reason .. "\n" ..
			"Date: " .. banData.banDate .. "\n\n" ..
			"If you believe this ban was issued in error, please contact the game administrators."
		player:Kick(kickMessage)
	end
end)

return {}
