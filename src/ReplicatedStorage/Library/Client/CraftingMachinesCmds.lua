--!strict

--[[
	Client-side CraftingMachines commands.
	Handles client-side validation and server communication.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local CraftingMachineTypes = require(ReplicatedStorage.Game.Library.Types.CraftingMachines)
local Event = require(ReplicatedStorage.Library.Modules.Event)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)

local CraftingMachinesCmds = {}

-- Cache for recipe ingredients: [MachineId][RecipeIndex] = recipe_ingredients_schema
local recipeIngredientsCache: {[string]: {[number]: CraftingMachineTypes.recipe_ingredients_schema?}} = {}

-- Event that fires when recipe data is updated
CraftingMachinesCmds.RecipesUpdated = Event.new()

-- Check if player can craft a recipe (client-side validation)
function CraftingMachinesCmds.CanCraft(craftingMachineIdOrDir: string | CraftingMachineTypes.dir_schema, recipeIndex: number): boolean
	local save = Save.Get()
	if not save then
		return false
	end
	
	-- Get crafting machine ID
	local craftingMachineId: string
	if typeof(craftingMachineIdOrDir) == "table" then
		craftingMachineId = (craftingMachineIdOrDir :: CraftingMachineTypes.dir_schema)._id
	else
		craftingMachineId = craftingMachineIdOrDir :: string
	end
	
	local schema = Directory.CraftingMachines[craftingMachineId]
	if not schema then
		return false
	end
	
	local recipe = schema.Recipes[recipeIndex]
	if not recipe then
		return false
	end
	
	-- Check if slot is occupied
	local recipeKey = tostring(recipeIndex)
	if save.CraftingMachines and save.CraftingMachines[craftingMachineId] and save.CraftingMachines[craftingMachineId][recipeKey] then
		return false
	end
	
	-- Check money
	local money = save.PlotSave and save.PlotSave.Variables and save.PlotSave.Variables.Money or 0
	if money < recipe.CraftCost then
		return false
	end
	
	-- Get ingredients from cache
	local ingredients = recipeIngredientsCache[craftingMachineId] and recipeIngredientsCache[craftingMachineId][recipeIndex]
	
	if not ingredients then
		return false
	end
	
	-- Check if player has all required ingredients
	for _, ingredientParam in ipairs(ingredients.Ingredients) do
		local hasFish = false
		if save.Inventory then
			for _, fishData in ipairs(save.Inventory) do
				if fishData.FishId == ingredientParam.FishId and fishData.Type == ingredientParam.Type then
					hasFish = true
					break
				end
			end
		end
		
		if not hasFish then
			return false
		end
	end
	
	return true
end

-- Craft a recipe
function CraftingMachinesCmds.Craft(craftingMachineIdOrDir: string | CraftingMachineTypes.dir_schema, recipeIndex: number): boolean
	-- Check if can craft
	if not CraftingMachinesCmds.CanCraft(craftingMachineIdOrDir, recipeIndex) then
		return false
	end
	
	-- Get crafting machine ID
	local craftingMachineId: string
	if typeof(craftingMachineIdOrDir) == "table" then
		craftingMachineId = (craftingMachineIdOrDir :: CraftingMachineTypes.dir_schema)._id
	else
		craftingMachineId = craftingMachineIdOrDir :: string
	end
	
	-- Ask server to craft
	local success, result = pcall(function()
		return Network.Invoke("CraftingMachines_Craft", craftingMachineId, recipeIndex)
	end)
	
	if success and result then
		return true
	end
	
	return false
end

-- Check if a recipe is ready to claim
function CraftingMachinesCmds.IsRecipeReady(craftingMachineIdOrDir: string | CraftingMachineTypes.dir_schema, recipeIndex: number): boolean
	local save = Save.Get()
	if not save then
		return false
	end
	
	-- Get crafting machine ID
	local craftingMachineId: string
	if typeof(craftingMachineIdOrDir) == "table" then
		craftingMachineId = (craftingMachineIdOrDir :: CraftingMachineTypes.dir_schema)._id
	else
		craftingMachineId = craftingMachineIdOrDir :: string
	end
	
	if not save.CraftingMachines or not save.CraftingMachines[craftingMachineId] then
		return false
	end
	
	local recipeKey = tostring(recipeIndex)
	local slot = save.CraftingMachines[craftingMachineId][recipeKey]
	if not slot then
		return false
	end
	
	local currentTime = workspace:GetServerTimeNow()
	return currentTime >= slot.CompletionTime
end

-- Claim a completed recipe
function CraftingMachinesCmds.Claim(craftingMachineIdOrDir: string | CraftingMachineTypes.dir_schema, recipeIndex: number): boolean
	-- Check if ready to claim
	if not CraftingMachinesCmds.IsRecipeReady(craftingMachineIdOrDir, recipeIndex) then
		return false
	end
	
	-- Check if inventory is full
	local save = Save.Get()
	if save then
		local inventorySize = save.PlotSave and save.PlotSave.Variables and save.PlotSave.Variables.InventorySize or 0
		local currentInventoryCount = #save.Inventory
		
		if currentInventoryCount >= inventorySize then
			NotificationCmds.Message("You need to make room in your inventory first!", {
				Color = Color3.fromRGB(255, 0, 0),
			})
			return false 
		end
	end
	
	-- Get crafting machine ID
	local craftingMachineId: string
	if typeof(craftingMachineIdOrDir) == "table" then
		craftingMachineId = (craftingMachineIdOrDir :: CraftingMachineTypes.dir_schema)._id
	else
		craftingMachineId = craftingMachineIdOrDir :: string
	end
	
	-- Ask server to claim
	local success, result = pcall(function()
		return Network.Invoke("CraftingMachines_Claim", craftingMachineId, recipeIndex)
	end)
	
	if success and result then
		return true
	end
	
	return false
end

-- Get craft data for a recipe
function CraftingMachinesCmds.GetCraftData(craftingMachineIdOrDir: string | CraftingMachineTypes.dir_schema, recipeIndex: number): {
	TimeRemaining: number?,
	IsReady: boolean,
	IsCrafting: boolean,
	Recipe: CraftingMachineTypes.recipe_data_schema?,
	RecipeIngredients: CraftingMachineTypes.recipe_ingredients_schema?,
}
	local save = Save.Get()
	
	-- Get crafting machine ID
	local craftingMachineId: string
	if typeof(craftingMachineIdOrDir) == "table" then
		craftingMachineId = (craftingMachineIdOrDir :: CraftingMachineTypes.dir_schema)._id
	else
		craftingMachineId = craftingMachineIdOrDir :: string
	end
	
	local schema = Directory.CraftingMachines[craftingMachineId]
	local recipe = schema and schema.Recipes[recipeIndex]
	
	if not save or not schema or not recipe then
		return {
			TimeRemaining = nil,
			IsReady = false,
			IsCrafting = false,
			Recipe = recipe,
			RecipeIngredients = nil,
		}
	end
	
	local recipeKey = tostring(recipeIndex)
	local slot = save.CraftingMachines and save.CraftingMachines[craftingMachineId] and save.CraftingMachines[craftingMachineId][recipeKey]
	
	local isCrafting = slot ~= nil
	local isReady = false
	local timeRemaining = nil
	
	if isCrafting and slot then
		local currentTime = workspace:GetServerTimeNow()
		isReady = currentTime >= slot.CompletionTime
		timeRemaining = math.max(0, slot.CompletionTime - currentTime)
	end
	
	-- Get recipe ingredients from cache
	local recipeIngredients = recipeIngredientsCache[craftingMachineId] and recipeIngredientsCache[craftingMachineId][recipeIndex]
	
	return {
		TimeRemaining = timeRemaining,
		IsReady = isReady,
		IsCrafting = isCrafting,
		Recipe = recipe,
		RecipeIngredients = recipeIngredients,
	}
end

-- Request recipe ingredients from server (called once on load)
local function fetchAllRecipeIngredients()
	for machineId, machineSchema in pairs(Directory.CraftingMachines) do
		recipeIngredientsCache[machineId] = {}
		
		for recipeIndex = 1, #machineSchema.Recipes do
			local success, result = pcall(function()
				return Network.Invoke("CraftingMachines_GetRecipeIngredients", machineId, recipeIndex)
			end)
			
			if success and result then
				recipeIngredientsCache[machineId][recipeIndex] = result
			end
		end
	end
	
	-- Fire event to notify listeners that recipes are loaded
	CraftingMachinesCmds.RecipesUpdated:FireAsync()
end

-- Listen for recipe updates from server
Network.Fired("CraftingMachines_RecipesUpdated", function(machineId: string, recipes: {[number]: CraftingMachineTypes.recipe_ingredients_schema})
	if not recipeIngredientsCache[machineId] then
		recipeIngredientsCache[machineId] = {}
	end
	
	for recipeIndex, recipeData in pairs(recipes) do
		recipeIngredientsCache[machineId][recipeIndex] = recipeData
	end
	
	-- Fire event to notify listeners
	CraftingMachinesCmds.RecipesUpdated:FireAsync(machineId)
end)

-- Initialize: fetch recipe ingredients once when module loads
task.spawn(function()
	-- Wait for save to be loaded
	while not Save.Get() do
		task.wait(0.1)
	end
	
	task.wait(0.5) -- Small delay to ensure everything is ready
	fetchAllRecipeIngredients()
end)

return CraftingMachinesCmds

