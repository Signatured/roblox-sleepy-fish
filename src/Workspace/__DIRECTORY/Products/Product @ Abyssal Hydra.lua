--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

return {
	ProductId = 3402065537,
	DisplayName = "[OP] Exclusive Abyssal Hydra",
	Icon = "rbxassetid://111872157833540",
	Description = "Fish is 150% as strong as your best fish!",
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
		local ExistCount = require(game.ServerScriptService.Game.Library.ExistCount)
		local Index = require(game.ServerScriptService.Game.Library.Index)
		local Functions = require(game.ReplicatedStorage.Library.Functions)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local typeChances = {
			["Normal"] = 79,
			["Shiny"] = 15,
			["Gold"] = 5,
			["Rainbow"] = 1,
		}

		local mutation: FishTypes.fish_mutation_type? = nil
		if math.random() <= 0.1 then
			mutation = "Bloodfish"
		end

		local data = Fish.Give(player, {
			FishId = "Abyssal Hydra",
			Type = Functions.Lottery(typeChances),
			Mutation = mutation
		})

		if data then
			Fish.ForceHoldFish(player, data)
			ExistCount.IncrementCount(data.FishId, data.Type)
			Index.Add(player, data.FishId, data.Type, data.Mutation)
		end

		return true
	end,
}