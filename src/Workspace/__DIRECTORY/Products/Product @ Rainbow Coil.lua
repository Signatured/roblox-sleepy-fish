--!strict

return {
	ProductId = 3379949669,
	DisplayName = "Rainbow Coil",
	Icon = "rbxassetid://113359210467566",
	Description = "Gives a Rainbow Coil!",
	OneTimePurchase = false,
	ClientTest = function(player: Player): (boolean, string?)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
		local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)

		local plot = ClientPlot.GetLocal()

		if GadgetCmds.Has("Rainbow Coil") then
			return false, "You already have a Rainbow Coil!"
		end

		return plot ~= nil
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local Gadgets = require(game.ServerScriptService.Game.Library.Gadgets)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		if Gadgets.Has(player, "Rainbow Coil") then
			return false, "You already have a Rainbow Coil!"
		end

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local Gadgets = require(game.ServerScriptService.Game.Library.Gadgets)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local ok = Gadgets.GiveAndInventory(player, "Rainbow Coil")
		if not ok then
			return false, "Already owned or could not grant."
		end

		return true
	end,
}