--!strict

return {
	ProductId = 3385992733,
	DisplayName = "Magic Carpet",
	Icon = "rbxassetid://133946398396934",
	Description = "Gives a Magic Carpet!",
	OneTimePurchase = false,
	ClientTest = function(player: Player): (boolean, string?)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
		local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)

		local plot = ClientPlot.GetLocal()

		if GadgetCmds.Has("Magic Carpet") then
			return false, "You already have a Magic Carpet!"
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

		if Gadgets.Has(player, "Magic Carpet") then
			return false, "You already have a Magic Carpet!"
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

		local ok = Gadgets.GiveAndInventory(player, "Magic Carpet")
		if not ok then
			return false, "Already owned or could not grant."
		end

		return true
	end,
}