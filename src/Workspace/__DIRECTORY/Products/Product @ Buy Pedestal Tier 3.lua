--!strict

local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)

return {
	ProductId = 3376777349,
	DisplayName = "Buy Pedestal!",
	Icon = "",
	Description = "Unlock a pedestal for your plot!",
	OneTimePurchase = false,
	ClientTest = function(player: Player): (boolean, string?)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

		local plot = ClientPlot.GetLocal()
		if not plot then
			return false, "No plot found!"
		end

		local pedestals = plot:Save("Pedestals")::number

		if pedestals >= GameSettings.PedestalCount then
			return false, "Max pedestals reached!"
		end

		return true
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local pedestals = plot:Save("Pedestals")::number

		if pedestals >= GameSettings.PedestalCount then
			return false, "Max pedestals reached!"
		end

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local pedestals = plot:Save("Pedestals")::number

		if pedestals >= GameSettings.PedestalCount then
			return false, "Max pedestals reached!"
		end

		plot:SaveSet("Pedestals", pedestals + 1)

		return true
	end,
}