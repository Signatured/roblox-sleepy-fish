--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerPlot = require(ServerScriptService.Plot.ServerPlot)
local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local GameSettings = require(ReplicatedStorage.Game.Library.GameSettings)
local Notifications = require(ServerScriptService.Library.Notifications)

local Command = { 
	Name = "GiveSpace",
	Aliases = {"givespace", "space", "gs"},
	Permissions = {"Admin", "Owner", "Developer"}, 
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]

		for _, targetPlayer in ipairs(targetPlayers) do
			local plot = ServerPlot.GetByPlayer(targetPlayer)

			if plot then
				local invSize = plot:Save("InventorySize")::number?
				
				if not invSize then
					Notifications.Message(player, "No inventory size found!", {
						Color = Color3.fromRGB(255, 0, 0),
					})
					continue
				end
				
				if invSize >= GameSettings.MaxInventoryUpgraded3 then
					Notifications.Message(player, "That player already has max inventory size!", {
						Color = Color3.fromRGB(255, 0, 0),
					})
					continue
				end
				
				local newSize = GameSettings.MaxInventoryUpgraded1
				if invSize >= GameSettings.MaxInventoryUpgraded1 then
					newSize = GameSettings.MaxInventoryUpgraded2
				end
				if invSize >= GameSettings.MaxInventoryUpgraded2 then
					newSize = GameSettings.MaxInventoryUpgraded3
				end
				
				plot:SaveSet("InventorySize", newSize)
				
				Notifications.Message(player, `Upgraded player's storage to {newSize}!`, {
					Color = Color3.fromRGB(0, 255, 0),
				})
			end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {} 

