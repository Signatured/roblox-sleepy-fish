--!strict

return {
	ProductId = 3385884544,
	DisplayName = "[OP] Make All Fish Sleep!",
	Icon = "rbxassetid://109838009828589",
	Description = "Make all fish sleep!",
	OneTimePurchase = false,
	ClientTest = function(player: Player)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

		local plot = ClientPlot.GetLocal()
		return plot ~= nil
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local Notifications = require(game.ServerScriptService.Library.Notifications)
		local Enemies = require(game.ServerScriptService.Game.Library.Enemies)

		Enemies.SleepAll(60)

		Notifications.MessageAll(`{player.DisplayName} made all fish sleep for 60 seconds!`, {
			Rainbow = true,
			Time = 8
		})

		return true
	end,
}