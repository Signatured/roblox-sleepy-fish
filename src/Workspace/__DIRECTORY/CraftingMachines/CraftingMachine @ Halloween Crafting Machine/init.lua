--!strict

local CraftingMachineTypes = require(game.ReplicatedStorage.Game.Library.Types.CraftingMachines)

return {
	DisplayName = "Halloween Crafting Machine",
	RecipeResetTime = 60 * 60, -- 1 hour in seconds
	Recipes = {
		{
			RarityResult = "Epic",
			CraftTime = 60 * 5, -- 5 minutes
			CraftCost = 50_000,
			RequiredIngredientAmount = 4,
			TrailingFishAmount = 7,
		},
		{
			RarityResult = "Legendary",
			CraftTime = 60 * 15, -- 15 minutes
			CraftCost = 300_000,
			RequiredIngredientAmount = 4,
			TrailingFishAmount = 7,
		},
		{
			RarityResult = "Mythical",
			CraftTime = 60 * 30, -- 30 minutes
			CraftCost = 50_000_000,
			RequiredIngredientAmount = 4,
			TrailingFishAmount = 8,
		},
		{
			RarityResult = "God",
			CraftTime = 60 * 45, -- 45 minutes
			CraftCost = 750_000_000,
			RequiredIngredientAmount = 4,
			TrailingFishAmount = 9,
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
			TrailingFishAmount = 10,
		},
	}
}::CraftingMachineTypes.raw_dir

