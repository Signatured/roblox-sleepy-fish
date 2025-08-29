--!strict

return {
	ProductId = 3388315092,
	DisplayName = "[OP] Spawn Mythical Fish!",
	Icon = "rbxassetid://109838009828589",
	Description = "Forces a mythical fish to spawn!",
	OneTimePurchase = false,
	ClientTest = function(player: Player)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

		local plot = ClientPlot.GetLocal()
		return plot ~= nil
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local LimitedMythicalOffer = require(game.ServerScriptService.Game.Library.LimitedMythicalOffer)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		if not LimitedMythicalOffer.CanPurchase(player) then
			return false, "This deal  has expired!"
		end

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local LimitedMythicalOffer = require(game.ServerScriptService.Game.Library.LimitedMythicalOffer)

		LimitedMythicalOffer.ExecutePurchase(player)

		return true
	end,
}