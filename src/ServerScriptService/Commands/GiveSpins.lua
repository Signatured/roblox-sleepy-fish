--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Saving = require(ServerScriptService.Library.Saving)
local Notifications = require(ServerScriptService.Library.Notifications)
local SpinnyWheelDirectory = require(ReplicatedStorage.Game.Library.Directory.SpinnyWheels)

local Command = {
	Name = "GiveSpins",
	Aliases = {"givespins", "spins"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
		{Type = "String", Name = "WheelId"},
		{Type = "Number", Name = "Amount"},
		{Type = "String", Name = "SpinType", Optional = true}, -- "Free" or "Paid" (default: "Free")
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]
		local wheelId = args[2]
		local amount = args[3]
		local spinType = args[4] or "Free"

		-- Normalize spinType to proper case
		if spinType:lower() == "free" then
			spinType = "Free"
		elseif spinType:lower() == "paid" then
			spinType = "Paid"
		else
			warn(`[GiveSpins] Invalid spin type: {spinType}. Using "Free" instead.`)
			spinType = "Free"
		end

		-- Validate wheel exists
		if not SpinnyWheelDirectory[wheelId] then
			warn(`[GiveSpins] Invalid wheel ID: {wheelId}`)
			return
		end

		-- Validate amount
		if amount <= 0 then
			warn(`[GiveSpins] Amount must be greater than 0`)
			return
		end

		-- Get wheel display name for notification
		local wheelSchema = SpinnyWheelDirectory[wheelId]
		local wheelDisplayName = wheelSchema and wheelSchema.DisplayName or wheelId

		for _, targetPlayer in ipairs(targetPlayers) do
			local saveData = Saving.Get(targetPlayer)
			if not saveData then
				warn(`[GiveSpins] Could not get save data for {targetPlayer.Name}`)
				continue
			end

			-- Initialize wheels table if needed
			saveData.Wheels = saveData.Wheels or {}
			saveData.Wheels[wheelId] = saveData.Wheels[wheelId] or { Free = 0, Paid = 0, FreeNextAt = nil }

			-- Add spins
			if spinType == "Free" then
				saveData.Wheels[wheelId].Free = (saveData.Wheels[wheelId].Free or 0) + amount
			else
				saveData.Wheels[wheelId].Paid = (saveData.Wheels[wheelId].Paid or 0) + amount
			end

			-- Send rainbow notification to the player
			Notifications.Message(targetPlayer, `Admin gave you {amount} {wheelDisplayName} spins!`, {
				Rainbow = true,
				Time = 7,
			})

			print(`[GiveSpins] Gave {amount} {spinType} spins for wheel "{wheelId}" to {targetPlayer.Name}`)
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

