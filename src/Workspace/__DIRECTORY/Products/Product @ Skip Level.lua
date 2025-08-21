--!strict

return {
	ProductId = 3375483794,
	DisplayName = "[OP] Skip Level!",
	Icon = "",
	Description = "Skip a level for a fish!",
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
		local PurchaseLevel = require(game.ServerScriptService.Game.Library.PurchaseLevel)

		local success = PurchaseLevel.ExecuteLevelUp(player)
		if not success then
			return false, "That fish no longer exists!"
		end

		return true
	end,
}