--!strict

--[[
	Server-side handler for the AbusePanel.
	Handles command execution requests from the AbusePanel UI by forwarding them to the CommandManager.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local CommandManager = require(ServerScriptService.CommandManager)
local Notifications = require(ServerScriptService.Library.Notifications)

local AbusePanel = {}

-- Build command string from parameters
local function BuildCommandString(commandName: string, ...: string?): string
	local parts = {`/{commandName}`}
	
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if arg and arg ~= "" then
			-- Quote the argument if it contains spaces
			if string.find(arg, " ") then
				table.insert(parts, `"{arg}"`)
			else
				table.insert(parts, arg)
			end
		end
	end
	
	return table.concat(parts, " ")
end

-- Handle GlobalMessage command
Network.Fired("AbusePanel_GlobalMessage", function(player: Player, message: string?)
	if not message or message == "" then
		Notifications.Message(player, "Message is required", {Color = Color3.fromRGB(255, 100, 100)})
		return
	end
	
	local commandStr = BuildCommandString("GlobalMessage", message)
	CommandManager.ProcessCommand(player, commandStr)
	Notifications.Message(player, "GlobalMessage executed", {Color = Color3.fromRGB(100, 255, 100)})
end)

-- Handle GlobalForceSpawn command
Network.Fired("AbusePanel_GlobalForceSpawn", function(player: Player, fishId: string?, fishType: string?, mutation: string?, traits: string?)
	if not fishId or fishId == "" then
		Notifications.Message(player, "Fish ID is required", {Color = Color3.fromRGB(255, 100, 100)})
		return
	end
	
	local commandStr = BuildCommandString("GlobalForceSpawn", fishId, fishType, mutation, traits)
	CommandManager.ProcessCommand(player, commandStr)
	Notifications.Message(player, "GlobalForceSpawn executed", {Color = Color3.fromRGB(100, 255, 100)})
end)

-- Handle GlobalForceGive command
Network.Fired("AbusePanel_GlobalForceGive", function(player: Player, fishId: string?, fishType: string?, mutation: string?, traits: string?, level: number?)
	if not fishId or fishId == "" then
		Notifications.Message(player, "Fish ID is required", {Color = Color3.fromRGB(255, 100, 100)})
		return
	end
	
	local levelStr = level and tostring(level) or nil
	local commandStr = BuildCommandString("GlobalForceGive", fishId, fishType, mutation, traits, levelStr)
	CommandManager.ProcessCommand(player, commandStr)
	Notifications.Message(player, "GlobalForceGive executed", {Color = Color3.fromRGB(100, 255, 100)})
end)

-- Handle GlobalForceRarity command
Network.Fired("AbusePanel_GlobalForceRarity", function(player: Player, rarityId: string?, fishType: string?, mutation: string?, traits: string?)
	if not rarityId or rarityId == "" then
		Notifications.Message(player, "Rarity ID is required", {Color = Color3.fromRGB(255, 100, 100)})
		return
	end
	
	local commandStr = BuildCommandString("GlobalForceRarity", rarityId, fishType, mutation, traits)
	CommandManager.ProcessCommand(player, commandStr)
	Notifications.Message(player, "GlobalForceRarity executed", {Color = Color3.fromRGB(100, 255, 100)})
end)

-- Handle GlobalGiveSpins command
Network.Fired("AbusePanel_GlobalGiveSpins", function(player: Player, wheelId: string?, amount: number?, spinType: string?)
	if not wheelId or wheelId == "" then
		Notifications.Message(player, "Wheel ID is required", {Color = Color3.fromRGB(255, 100, 100)})
		return
	end
	
	if not amount or amount <= 0 then
		Notifications.Message(player, "Amount must be greater than 0", {Color = Color3.fromRGB(255, 100, 100)})
		return
	end
	
	local amountStr = tostring(amount)
	local commandStr = BuildCommandString("GlobalGiveSpins", wheelId, amountStr, spinType)
	CommandManager.ProcessCommand(player, commandStr)
	Notifications.Message(player, "GlobalGiveSpins executed", {Color = Color3.fromRGB(100, 255, 100)})
end)

return AbusePanel

