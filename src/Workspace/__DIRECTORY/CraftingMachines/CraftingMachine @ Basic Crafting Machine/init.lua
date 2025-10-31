--!strict

local CraftingMachineTypes = require(game.ReplicatedStorage.Game.Library.Types.CraftingMachines)

return {
	DisplayName = "Basic Crafting Machine",
	RecipeResetTime = 10800, -- 3 hours in seconds
	Recipes = {
		{
			RarityResult = "Epic",
			CraftTime = 10,--60 * 5, -- 5 minutes
			CraftCost = 50_000,
			RequiredIngredientAmount = 4,
		},
		{
			RarityResult = "Legendary",
			CraftTime = 60 * 15, -- 15 minutes
			CraftCost = 300_000,
			RequiredIngredientAmount = 4,
		},
		{
			RarityResult = "Mythical",
			CraftTime = 60 * 30, -- 30 minutes
			CraftCost = 50_000_000,
			RequiredIngredientAmount = 4,
		},
		{
			RarityResult = "God",
			CraftTime = 60 * 45, -- 45 minutes
			CraftCost = 750_000_000,
			RequiredIngredientAmount = 4,
		},
		{
			FishResult = {
				FishId = "Evil Loch Ness Monster",
				Type = "Normal",
			},
			RarityResult = "Secret",
			CraftTime = 60 * 60 * 1.5, -- 1.5 hours
			CraftCost = 5_000_000_000,
			RequiredIngredientAmount = 4,
		},
	}
}::CraftingMachineTypes.raw_dir

