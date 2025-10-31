--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

local module = {}

export type raw_dir = {
	DisplayName: string,
	RecipeResetTime: number,
	Recipes: {recipe_data_schema},
}

export type recipe_data_schema = {
	FishResult: FishTypes.create_params?, -- if provided, use this over RarityResult
	RarityResult: string, -- use as backup for FishResult if FishResult is not provided
	CraftTime: number,
	CraftCost: number,
	RequiredIngredientAmount: number,
	TrailingFishAmount: number,
}

export type recipe_ingredients_schema = {
	Result: FishTypes.create_params,
	Ingredients: {FishTypes.create_params},
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module
