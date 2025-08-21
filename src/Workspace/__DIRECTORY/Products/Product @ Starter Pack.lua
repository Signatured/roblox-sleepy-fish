--!strict

return {
	ProductId = 3379060688,
	DisplayName = "Starter Pack",
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

		local data = Fish.Give(player, {
			FishId = "Anglerfish",
			Type = "Normal"
		})
		plot:AddMoney(5_000)
		Gadgets.GiveAndInventory(player, "Springy Coil")

		if data then
			Fish.ForceHoldFish(player, data)
		end

		return true
	end,
}