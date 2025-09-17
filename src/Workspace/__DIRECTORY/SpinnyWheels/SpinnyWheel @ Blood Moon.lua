--!strict

local SpinnyWheelTypes = require(game.ReplicatedStorage.Game.Library.Types.SpinnyWheels)
local Audio = require(game.ReplicatedStorage.Library.Audio)
local Functions = require(game.ReplicatedStorage.Library.Functions)


return {
	DisplayName = "Blood Moon Wheel",
	Description = "",
	Cost = 1_000,
	Rewards = {
		{
			Index = 1,
			Weight = 1,
			DisplayChance = "1%",
			Icon = "rbxassetid://86029483075689",
			Quantity = 1,
			AltText = "Magic Carpet!"
		},
		{
			Index = 2,
			Weight = 4,
			DisplayChance = "4%",
			Icon = "rbxassetid://108187777978992",
			Quantity = 30000,
		},
		{
			Index = 3,
			Weight = 10,
			DisplayChance = "10%",
			Icon = "rbxassetid://108187777978992",
			Quantity = 5000,
		},
		{
			Index = 4,
			Weight = 20,
			DisplayChance = "20%",
			Icon = "rbxassetid://108187777978992",
			Quantity = 2500,
		},
		{
			Index = 5,
			Weight = 30,
			DisplayChance = "30%",
			Icon = "rbxassetid://108187777978992",
			Quantity = 500,
		},
		{
			Index = 6,
			Weight = 35,
			DisplayChance = "35%",
			Icon = "rbxassetid://108187777978992",
			Quantity = 100,
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
			local Gadgets = require(game.ServerScriptService.Library.Gadgets)
			
			Gadgets.Give(player, "Magic Carpet")
			
			Audio.Play("rbxassetid://73120673212122", player)
			Notifications.Message(player, `Given a Magic Carpet!`, {
				Color = Color3.new(255, 0, 255)
			})
		else
			save.Coins += reward.Quantity
			
			Notifications.Message(player, `Congrats on winning ${Functions.Commas(reward.Quantity)}!`, {
				Color = Color3.new(255, 0, 255)
			})
		end
	end,
}::SpinnyWheelTypes.raw_dir