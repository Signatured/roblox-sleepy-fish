--!strict

return {
	ProductId = 3420310943,
	DisplayName = "[OP] Secret Lucky Block",
	Icon = "rbxassetid://111872157833540",
	Description = "Open for a God fish!",
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
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local Fish = require(game.ServerScriptService.Game.Library.Fish)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local data = Fish.Give(player, {
			FishId = "Secret Lucky Block",
			Type = "Normal"
		})

		if data then
			Fish.ForceHoldFish(player, data)
		end

		return true
	end,
}