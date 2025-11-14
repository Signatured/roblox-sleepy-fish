--!strict

local SpinnyWheelTypes = require(game.ReplicatedStorage.Game.Library.Types.SpinnyWheels)
local Functions = require(game.ReplicatedStorage.Library.Functions)

return {
	DisplayName = "Yin Yang Wheel",
	Description = "",
	Rewards = {
		{
			Index = 1,
			Weight = 1,
			DisplayChance = "1%",
			Icon = "rbxassetid://122931667882291",
			Title1 = "YingYang",
			Title2 = "Ancient Sea Dragon",
			Title3 = "$1.65k/s",
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
			Icon = "rbxassetid://132548168145204",
			Title1 = "God",
			Title2 = "Lucky Block",
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
			Icon = "rbxassetid://130334998181902",
			Title1 = "4x Server",
			Title2 = "Luck!",
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
	
			local data = Fish.Give(player, {
				FishId = "Ancient Sea Dragon",
				Type = "Normal",
				Mutation = "YingYang"
			})
	
			if data then
				Fish.ForceHoldFish(player, data)
				ExistCount.IncrementCount(data.FishId, data.Type)
				if data.Mutation == "YingYang" then
					ExistCount.IncrementMutationCount(data.FishId, data.Mutation)
				end
				Index.Add(player, data.FishId, data.Type, data.Mutation)
			end

			Notifications.Message(player, `You won a Yin Yang Ancient Sea Dragon!`, {
				Rainbow = true,
				Time = 8,
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
			local Fish = require(game.ServerScriptService.Game.Library.Fish)
	
			local data = Fish.Give(player, {
				FishId = "God Lucky Block",
				Type = "Normal"
			})
	
			if data then
				Fish.ForceHoldFish(player, data)
			end

			Notifications.Message(player, `You won a God Lucky Block!`, {
				Rainbow = true,
				Time = 8,
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
			local ServerLuck = require(game.ServerScriptService.Game.Library.ServerLuck)

			ServerLuck.Activate2xLuck(player)
			ServerLuck.Activate4xLuck(player)

			Notifications.Message(player, `You won 4x Server Luck for 20 minutes!`, {
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