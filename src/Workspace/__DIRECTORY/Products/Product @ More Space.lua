--!strict

return {
	ProductId = 3379337315,
	DisplayName = "More Space",
	Icon = "",
	Description = "Gives more inventory space!",
	OneTimePurchase = false,
	ClientTest = function(player: Player)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

		local plot = ClientPlot.GetLocal()
		return plot ~= nil
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local invSize = plot:Save("InventorySize")::number?
		if not invSize then
			return false, "No inventory size found!"
		end
		if invSize >= GameSettings.MaxInventoryUpgraded3 then
			return false, "You already have the max inventory size!"
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

		local invSize = plot:Save("InventorySize")::number?
		if not invSize then
			return false, "No inventory size found!"
		end
		if invSize >= GameSettings.MaxInventoryUpgraded3 then
			return false, "You already have the max inventory size!"
		end

		local newSize = GameSettings.MaxInventoryUpgraded1
		if invSize >= GameSettings.MaxInventoryUpgraded1 then
			newSize = GameSettings.MaxInventoryUpgraded2
		end
		if invSize >= GameSettings.MaxInventoryUpgraded2 then
			newSize = GameSettings.MaxInventoryUpgraded3
		end

		plot:SaveSet("InventorySize", newSize)

		return true
	end,
}