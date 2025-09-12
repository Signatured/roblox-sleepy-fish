--!strict

return {
	ProductId = 3402108805,
	DisplayName = "Galaxy Coil",
	Icon = "rbxassetid://76699176695216",
	Description = "Gives a Galaxy Coil!",
	OneTimePurchase = false,
	ClientTest = function(player: Player): (boolean, string?)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
		local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)

		local plot = ClientPlot.GetLocal()

		if GadgetCmds.Has("Galaxy Coil") then
			return false, "You already have a Galaxy Coil!"
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

		if Gadgets.Has(player, "Galaxy Coil") then
			return false, "You already have a Galaxy Coil!"
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

		local ok = Gadgets.GiveAndInventory(player, "Galaxy Coil")
		if not ok then
			return false, "Already owned or could not grant."
		end

		return true
	end,
}