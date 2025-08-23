--!strict

return {
	ProductId = 3376073367,
	DisplayName = "[OP] 4x Server Luck!",
	Icon = "",
	Description = "Activate 4x server luck!",
	OneTimePurchase = false,
	ClientTest = function(player: Player): (boolean, string?)
		local ServerLuckCmds = require(game.ReplicatedStorage.Game.Library.Client.ServerLuckCmds)

		if ServerLuckCmds.GetMultiplier() == 1 then
			return false, "You need to buy 2x server luck first!"
		end

		return ServerLuckCmds.GetMultiplier() > 1
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerLuck = require(game.ServerScriptService.Game.Library.ServerLuck)

		if ServerLuck.GetServerLuck() == 1 then
			return false, "You need to buy 2x server luck first!"
		end

		return ServerLuck.GetServerLuck() > 1
	end,
	Callback = function(player: Player): (boolean, string?)
		local ServerLuck = require(game.ServerScriptService.Game.Library.ServerLuck)
		local Notifications = require(game.ServerScriptService.Library.Notifications)

		local currentMultiplier = ServerLuck.GetServerLuck()

		if currentMultiplier == 1 then
			return false, "You need to buy 2x server luck first!"
		end

		ServerLuck.Activate4xLuck(player)

		Notifications.MessageAll("4x Server Luck has been activated by " .. player.DisplayName .. "!", {
			Color = Color3.fromRGB(0, 255, 255),
			Time = 10,
		})

		return true
	end,
}