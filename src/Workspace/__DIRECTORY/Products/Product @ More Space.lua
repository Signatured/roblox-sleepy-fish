--!strict

return {
	ProductId = 3379337315,
	DisplayName = "More Space",
	Icon = "",
	Description = "Gives more inventory space!",
	OneTimePurchase = true,
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
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		plot:SaveSet("InventorySize", GameSettings.MaxInventoryUpgraded)

		return true
	end,
}