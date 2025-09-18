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
			Icon = "rbxassetid://126732776258447",
			Title1 = "Bloodfish",
			Title2 = "Squid",
			Title3 = "$1.4k/s"
		},
		{
			Index = 2,
			Weight = 2,
			DisplayChance = "2%",
			Icon = "rbxassetid://130334998181902",
			Title1 = "4x Server",
			Title2 = "Luck!",
		},
		{
			Index = 3,
			Weight = 5,
			DisplayChance = "5%",
			Icon = "rbxassetid://132404695616099",
			Title1 = "Blood Moon",
			Title2 = "Coil",
		},
		{
			Index = 4,
			Weight = 7.5,
			DisplayChance = "7.5%",
			Icon = "rbxassetid://108187777978992",
			Title2 = "$10m",
		},
		{
			Index = 5,
			Weight = 34,
			DisplayChance = "34%",
			Icon = "rbxassetid://108187777978992",
			Title2 = "$500k",
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