--!strict

return {
	ProductId = 3372113126,
	DisplayName = "+0.5x Multi",
	Icon = "",
	Description = "+0.5x Multi",
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

		if plot:Session("PaidIndex") ~= 2 then
			return false, "You cannot buy this right now!"
		end

		plot:SessionSet("PaidIndex", 3)

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		if plot:Session("PaidIndex") ~= 2 then
			return false, "You cannot buy this right now!"
		end

		plot:SessionSet("PaidIndex", 3)

		return true
	end,
}