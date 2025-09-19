--!strict

local SpinnyWheelTypes = require(game.ReplicatedStorage.Game.Library.Types.SpinnyWheels)
local Audio = require(game.ReplicatedStorage.Library.Audio)
local Functions = require(game.ReplicatedStorage.Library.Functions)


return {
	DisplayName = "Blood Moon Wheel",
	Description = "",
	Rewards = {
		{
			Index = 1,
			Weight = 1,
			DisplayChance = "1%",
			Icon = "rbxassetid://126732776258447",
			Title1 = "Bloodfish",
			Title2 = "Squid",
			Title3 = "$1.4k/s"
		},
		{
			Index = 2,
			Weight = 7.5,
			DisplayChance = "7.5%",
			Icon = "rbxassetid://108187777978992",
			Title2 = "$10m",
		},
		{
			Index = 3,
			Weight = 2,
			DisplayChance = "2%",
			Icon = "rbxassetid://130334998181902",
			Title1 = "4x Server",
			Title2 = "Luck!",
		},
		{
			Index = 4,
			Weight = 34,
			DisplayChance = "34%",
			Icon = "rbxassetid://108187777978992",
			Title2 = "$500k",
		},
		{
			Index = 5,
			Weight = 5,
			DisplayChance = "5%",
			Icon = "rbxassetid://132404695616099",
			Title1 = "Blood Moon",
			Title2 = "Coil",
		},
		{
			Index = 6,
			Weight = 55,
			DisplayChance = "55%",
			Icon = "rbxassetid://108187777978992",
			Title2 = "$100k",
		}
	},
	GiveReward = function(player, reward)
		local Saving = require(game.ServerScriptService.Library.Saving)
		local Notifications = require(game.ServerScriptService.Library.Notifications)
		
		local save = Saving.Get(player)
		if not save then
			return
		end
		
		if reward.Index == 1 then
			local Fish = require(game.ServerScriptService.Game.Library.Fish)
			local ExistCount = require(game.ServerScriptService.Game.Library.ExistCount)
			local Index = require(game.ServerScriptService.Game.Library.Index)
			
			local typeChances = {
				["Normal"] = 79,
				["Shiny"] = 15,
				["Gold"] = 5,
				["Rainbow"] = 1,
			}
	
			local data = Fish.Give(player, {
				FishId = "Firefly Squid",
				Type = Functions.Lottery(typeChances)
			})

			if math.random() <= 0.1 then
				data.Mutation = "Bloodfish"
			end
	
			if data then
				Fish.ForceHoldFish(player, data)
				ExistCount.IncrementCount(data.FishId, data.Type)
				Index.Add(player, data.FishId, data.Type, data.Mutation)
			end

			Notifications.Message(player, `You won a Firefly Squid!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		elseif reward.Index == 2 then
			local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

			local money = 10_000_000

			local plot = ServerPlot.GetByPlayer(player)
			if plot then
				plot:AddMoney(money)
			end

			Notifications.Message(player, `You won ${Functions.Commas(money)}!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		elseif reward.Index == 3 then
			local ServerLuck = require(game.ServerScriptService.Game.Library.ServerLuck)

			ServerLuck.Activate2xLuck(player)
			ServerLuck.Activate4xLuck(player)

			Notifications.Message(player, `You won 4x Server Luck for 20 minutes!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		elseif reward.Index == 4 then
			local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

			local money = 500_000

			local plot = ServerPlot.GetByPlayer(player)
			if plot then
				plot:AddMoney(money)
			end

			Notifications.Message(player, `You won ${Functions.Commas(money)}!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		elseif reward.Index == 5 then
			local Gadgets = require(game.ServerScriptService.Library.Gadgets)

			if not Gadgets.Has(player, "Blood Moon Coil") then
				Gadgets.Give(player, "Blood Moon Coil")
			end

			Notifications.Message(player, `You won a Blood Moon Coil!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		elseif reward.Index == 6 then
			local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

			local money = 100_000

			local plot = ServerPlot.GetByPlayer(player)
			if plot then
				plot:AddMoney(money)
			end

			Notifications.Message(player, `You won ${Functions.Commas(money)}!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		end
	end,
}::SpinnyWheelTypes.raw_dir