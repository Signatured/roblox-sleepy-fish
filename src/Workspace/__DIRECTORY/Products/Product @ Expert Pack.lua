--!strict

return {
	ProductId = 3379061006,
	DisplayName = "Expert Pack",
	Icon = "rbxassetid://80376655364845",
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
		local ExistCount = require(game.ServerScriptService.Game.Library.ExistCount)
		local Index = require(game.ServerScriptService.Game.Library.Index)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local data = Fish.Give(player, {
			FishId = "Giant Jellyfish",
			Type = "Normal"
		})
		plot:AddMoney(50_000)
		Gadgets.GiveAndInventory(player, "Speed Coil")

		if data then
			Fish.ForceHoldFish(player, data)
			ExistCount.IncrementCount(data.FishId, data.Type)
			Index.Add(player, data.FishId, data.Type)
		end

		return true
	end,
}