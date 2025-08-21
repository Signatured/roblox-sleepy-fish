--!strict

return {
	ProductId = 3379061006,
	DisplayName = "Expert Pack",
	Icon = "",
	Description = "Gives a free fish, money and coil!",
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
		local Fish = require(game.ServerScriptService.Game.Library.Fish)
		local Gadgets = require(game.ServerScriptService.Game.Library.Gadgets)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		Fish.Give(player, {
			FishId = "Giant Jellyfish",
			Type = "Normal"
		})
		plot:AddMoney(100_000)
		Gadgets.GiveAndInventory(player, "Speed Coil")

		return true
	end,
}