--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local SpinnyWheelDirectory = require(ReplicatedStorage.Game.Library.Directory.SpinnyWheels)

local GLOBAL_GIVE_SPINS_TOPIC = "SleepyFish:GlobalGiveSpins"

local Command = {
	Name = "GlobalGiveSpins",
	Aliases = {"globalgivespins", "globalspins", "ggs"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "String", Name = "WheelId"},
		{Type = "Number", Name = "Amount"},
		{Type = "String", Name = "SpinType", Optional = true}, -- "Free" or "Paid" (default: "Free")
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local wheelId = args[1]
		local amount = args[2]
		local spinType = args[3] or "Free"

		if typeof(wheelId) ~= "string" or #wheelId == 0 then return end
		if typeof(amount) ~= "number" or amount <= 0 then return end

		-- Normalize spinType to proper case
		if spinType:lower() == "free" then
			spinType = "Free"
		elseif spinType:lower() == "paid" then
			spinType = "Paid"
		else
			warn(`[GlobalGiveSpins] Invalid spin type: {spinType}. Using "Free" instead.`)
			spinType = "Free"
		end

		-- Validate wheel exists
		if not SpinnyWheelDirectory[wheelId] then
			warn(`[GlobalGiveSpins] Invalid wheel ID: {wheelId}`)
			return
		end

		local payload = {
			wheelId = wheelId,
			amount = amount,
			spinType = spinType,
			sender = player.UserId
		}

		pcall(function()
			MessagingService:PublishAsync(GLOBAL_GIVE_SPINS_TOPIC, payload)
		end)

		print(`[GlobalGiveSpins] Published global give spins request: {amount} {spinType} spins for wheel "{wheelId}"`)
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

