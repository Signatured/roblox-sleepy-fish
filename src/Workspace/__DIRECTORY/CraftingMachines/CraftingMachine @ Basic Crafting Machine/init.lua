--!strict

local CraftingMachineTypes = require(game.ReplicatedStorage.Game.Library.Types.CraftingMachines)

return {
	DisplayName = "Basic Crafting Machine",
	RecipeResetTime = 10800, -- 3 hours in seconds
	Recipes = {
		{
			RarityResult = "Uncommon",
			CraftTime = 300, -- 5 minutes
			CraftCost = 1000,
			RequiredIngredientAmount = 3,
		},
		{
			RarityResult = "Rare",
			CraftTime = 600, -- 10 minutes
			CraftCost = 5000,
			RequiredIngredientAmount = 4,
		},
		{
			RarityResult = "Epic",
			CraftTime = 1200, -- 20 minutes
			CraftCost = 15000,
			RequiredIngredientAmount = 5,
		},
	}
}::CraftingMachineTypes.raw_dir

