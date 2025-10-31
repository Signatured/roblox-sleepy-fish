--!strict

--[[
	Server-side CraftingMachines library.
	Handles recipe generation, crafting, and claiming.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local CraftingMachineTypes = require(ReplicatedStorage.Game.Library.Types.CraftingMachines)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Saving = require(ServerScriptService.Library.Saving)
local Network = require(ServerScriptService.Library.Network)
local Fish = require(ServerScriptService.Game.Library.Fish)
local Notifications = require(ServerScriptService.Library.Notifications)
local Functions = require(ReplicatedStorage.Library.Functions)

local ServerPlot = require(ServerScriptService.Plot.ServerPlot)

local CraftingMachines = {}

-- Seeded random number generator
local function seededRandom(seed: number): number
	local x = math.sin(seed) * 10000
	return x - math.floor(x)
end

-- Epoch start time for crafting system
local CRAFTING_EPOCH_START = 1761930000

-- Get the current time interval for a specific crafting machine
local function getCurrentInterval(schema: CraftingMachineTypes.dir_schema): number
	local currentTime = workspace:GetServerTimeNow()
	local elapsedTime = currentTime - CRAFTING_EPOCH_START
	return math.floor(elapsedTime / schema.RecipeResetTime)
end

-- Track the current recipe intervals per machine
local currentIntervals: {[string]: number} = {}

-- Generate difficulty scaler weighted towards 0.5
-- Uses beta distribution-like approach with seed
local function generateDifficultyScaler(seed: number): number
	-- Use multiple random samples to create distribution weighted towards 0.5
	local r1 = seededRandom(seed)
	local r2 = seededRandom(seed + 1000)
	local r3 = seededRandom(seed + 2000)
	
	-- Average of three random numbers creates a distribution weighted towards 0.5
	local scaler = (r1 + r2 + r3) / 3
	
	return scaler
end

-- Get all fish sorted by MoneyPerSecond (excluding Exclusive rarity)
local function getFishByMoneyPerSecond(): {FishTypes.dir_schema}
	local fishList = {}
	for _, fishSchema in pairs(Directory.Fish) do
		if fishSchema.MoneyPerSecond and fishSchema.MoneyPerSecond > 0 and fishSchema.Rarity._id ~= "Exclusive" then
			table.insert(fishList, fishSchema)
		end
	end
	
	table.sort(fishList, function(a, b)
		return a.MoneyPerSecond < b.MoneyPerSecond
	end)
	
	return fishList
end

-- Find the trailing fish before the target fish (by money per second)
local function getTrailingFish(targetFishId: string, trailingAmount: number): {FishTypes.dir_schema}
	local allFish = getFishByMoneyPerSecond()
	local targetIndex = nil
	
	-- Find target fish index
	for i, fish in ipairs(allFish) do
		if fish._id == targetFishId then
			targetIndex = i
			break
		end
	end
	
	if not targetIndex then
		return {}
	end
	
	-- Get trailing fish (or as many as available)
	local trailingFish = {}
	local startIndex = math.max(1, targetIndex - trailingAmount)
	for i = startIndex, targetIndex - 1 do
		table.insert(trailingFish, allFish[i])
	end
	
	return trailingFish
end

-- Select ingredients based on difficulty scaler
local function selectIngredients(trailingFish: {FishTypes.dir_schema}, ingredientCount: number, seed: number, difficultyScaler: number): {FishTypes.dir_schema}
	if #trailingFish == 0 then
		return {}
	end
	
	local ingredients = {}
	local usedIndices = {}
	
	-- Determine range based on difficulty scaler
	-- 0 = easiest (lowest MPS), 1 = hardest (highest MPS)
	local totalFish = #trailingFish
	
	-- Calculate the range of indices to select from based on difficulty
	-- difficultyScaler 0 = bottom of list (indices 1 to ~40% of list)
	-- difficultyScaler 1 = top of list (indices ~60% to 100% of list)
	-- difficultyScaler 0.5 = middle of list (indices ~30% to 70% of list)
	local rangeSize = math.max(math.ceil(totalFish * 0.6), ingredientCount + 2) -- At least 60% of list or enough for ingredients
	local rangeStart = math.floor(difficultyScaler * (totalFish - rangeSize)) + 1
	rangeStart = math.clamp(rangeStart, 1, totalFish - ingredientCount + 1)
	local rangeEnd = math.min(rangeStart + rangeSize - 1, totalFish)
	
	for i = 1, ingredientCount do
		local attempts = 0
		local selectedIndex = nil
		
		-- Try to find an unused fish within the difficulty range
		while attempts < 200 do
			-- Generate a random index within the difficulty-based range
			local randomValue = seededRandom(seed + i * 100 + attempts)
			local index = rangeStart + math.floor(randomValue * (rangeEnd - rangeStart + 1))
			index = math.clamp(index, rangeStart, rangeEnd)
			
			if not usedIndices[index] then
				selectedIndex = index
				usedIndices[index] = true
				break
			end
			
			attempts = attempts + 1
		end
		
		-- If we couldn't find one in range, try any unused fish
		if not selectedIndex then
			for idx = 1, totalFish do
				if not usedIndices[idx] then
					selectedIndex = idx
					usedIndices[idx] = true
					break
				end
			end
		end
		
		if selectedIndex then
			table.insert(ingredients, trailingFish[selectedIndex])
		else
			warn(`[CraftingMachines] Failed to select ingredient {i}/{ingredientCount} - not enough unique fish in trailing pool`)
		end
	end
	
	return ingredients
end

-- Generate a result fish based on rarity or specific fish
local function generateResultFish(recipe: CraftingMachineTypes.recipe_data_schema, seed: number): FishTypes.create_params?
	-- If FishResult is specified, use it
	if recipe.FishResult then
		return recipe.FishResult
	end
	
	-- Otherwise, roll based on RarityResult
	local targetRarity = Directory.Rarity[recipe.RarityResult]
	if not targetRarity then
		warn(`[CraftingMachines] Invalid rarity: {recipe.RarityResult}`)
		return nil
	end
	
	-- Get all fish of this rarity (excluding Exclusive)
	local fishOfRarity = {}
	local totalWeight = 0
	
	for _, fishSchema in pairs(Directory.Fish) do
		if fishSchema.Rarity._id == recipe.RarityResult and fishSchema.Rarity._id ~= "Exclusive" then
			local weight = fishSchema.RarityWeight or 1
			table.insert(fishOfRarity, {fish = fishSchema, weight = weight})
			totalWeight = totalWeight + weight
		end
	end
	
	if #fishOfRarity == 0 then
		warn(`[CraftingMachines] No fish found for rarity: {recipe.RarityResult}`)
		return nil
	end
	
	-- Select fish based on weighted random
	local randomValue = seededRandom(seed)
	local cumulativeWeight = 0
	local selectedFish = nil
	
	for _, entry in ipairs(fishOfRarity) do
		cumulativeWeight = cumulativeWeight + entry.weight
		if randomValue <= cumulativeWeight / totalWeight then
			selectedFish = entry.fish
			break
		end
	end
	
	if not selectedFish then
		selectedFish = fishOfRarity[1].fish
	end
	
	return {
		FishId = selectedFish._id,
		Type = "Normal" :: "Normal",
	}
end

-- Get recipe ingredients for a specific crafting machine and recipe index
function CraftingMachines.GetRecipeIngredients(craftingMachineId: string, recipeIndex: number): CraftingMachineTypes.recipe_ingredients_schema?
	local schema = Directory.CraftingMachines[craftingMachineId]
	if not schema then
		return nil
	end
	
	local recipe = schema.Recipes[recipeIndex]
	if not recipe then
		return nil
	end
	
	local currentInterval = getCurrentInterval(schema)
	local seed = currentInterval + recipeIndex
	
	-- Generate result fish
	local resultFish = generateResultFish(recipe, seed)
	if not resultFish then
		return nil
	end
	
	-- Get trailing fish for ingredient selection
	local trailingAmount = recipe.TrailingFishAmount
	local trailingFish = getTrailingFish(resultFish.FishId, trailingAmount)
	if #trailingFish == 0 then
		warn(`[CraftingMachines] No trailing fish found for {resultFish.FishId}`)
		return nil
	end
	
	-- Generate difficulty scaler
	local difficultyScaler = generateDifficultyScaler(seed)
	
	-- Select ingredients
	local ingredientFish = selectIngredients(trailingFish, recipe.RequiredIngredientAmount, seed, difficultyScaler)
	
	-- Convert to create_params
	local ingredients: {FishTypes.create_params} = {}
	for _, fish in ipairs(ingredientFish) do
		table.insert(ingredients, {
			FishId = fish._id,
			Type = "Normal" :: "Normal",
		})
	end
	
	return {
		Result = resultFish,
		Ingredients = ingredients,
	} :: CraftingMachineTypes.recipe_ingredients_schema
end

-- Check if player can craft a recipe
function CraftingMachines.CanCraft(player: Player, craftingMachineId: string, recipeIndex: number): boolean
	local save = Saving.Get(player)
	if not save then
		return false
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
	if save.CraftingMachines[craftingMachineId] and save.CraftingMachines[craftingMachineId][recipeKey] then
		return false
	end
	
	-- Check money
	local plot = ServerPlot.GetByPlayer(player)
	if not plot then
		return false
	end
	
	local money = plot:GetMoney()
	if money < recipe.CraftCost then
		return false
	end
	
	-- Check ingredients
	local recipeData = CraftingMachines.GetRecipeIngredients(craftingMachineId, recipeIndex)
	if not recipeData then
		return false
	end
	
	-- Check if player has all required ingredients
	for _, ingredientParam in ipairs(recipeData.Ingredients) do
		local hasFish = false
		for _, fishData in ipairs(save.Inventory) do
			if fishData.FishId == ingredientParam.FishId and fishData.Type == ingredientParam.Type then
				hasFish = true
				break
			end
		end
		
		if not hasFish then
			return false
		end
	end
	
	return true
end

-- Craft a recipe
function CraftingMachines.Craft(player: Player, craftingMachineId: string, recipeIndex: number): boolean
	local save = Saving.Get(player)
	if not save then
		return false
	end
	
	if not CraftingMachines.CanCraft(player, craftingMachineId, recipeIndex) then
		return false
	end
	
	local schema = Directory.CraftingMachines[craftingMachineId]
	local recipe = schema.Recipes[recipeIndex]
	local recipeData = CraftingMachines.GetRecipeIngredients(craftingMachineId, recipeIndex)
	
	if not recipeData then
		return false
	end
	
	-- Remove ingredients from inventory
	local removedFish = {}
	for _, ingredientParam in ipairs(recipeData.Ingredients) do
		local removed = false
		for i = #save.Inventory, 1, -1 do
			local fishData = save.Inventory[i]
			if fishData.FishId == ingredientParam.FishId and fishData.Type == ingredientParam.Type then
				-- Check if this fish was already removed
				local alreadyRemoved = false
				for _, uid in ipairs(removedFish) do
					if uid == fishData.UID then
						alreadyRemoved = true
						break
					end
				end
				
				if not alreadyRemoved then
					Fish.Take(player, fishData.UID)
					table.insert(removedFish, fishData.UID)
					removed = true
					break
				end
			end
		end
		
		if not removed then
			-- Rollback - give back removed fish
			-- This shouldn't happen if CanCraft worked correctly
			warn(`[CraftingMachines] Failed to remove ingredient {ingredientParam.FishId}`)
			return false
		end
	end
	
	-- Remove money
	local plot = ServerPlot.GetByPlayer(player)
	if plot then
		plot:AddMoney(-recipe.CraftCost)
	end
	
	-- Set crafting in motion
	local currentTime = workspace:GetServerTimeNow()
	local completionTime = currentTime + recipe.CraftTime
	
	-- Initialize crafting machine table if it doesn't exist
	if not save.CraftingMachines[craftingMachineId] then
		save.CraftingMachines[craftingMachineId] = {}
	end
	
	local recipeKey = tostring(recipeIndex)
	save.CraftingMachines[craftingMachineId][recipeKey] = {
		RecipeIndex = recipeIndex,
		CompletionTime = completionTime,
		ResultFish = recipeData.Result,
	}
	
	local fishName = recipeData.Result.FishId
	local fishSchema = Directory.Fish[fishName]
	local displayName = fishSchema and fishSchema.DisplayName or fishName
	Notifications.Message(player, `Your {displayName} will be ready in {Functions.FormatTime(recipe.CraftTime)}!`, {
		Color = Color3.fromRGB(0, 255, 0),
	})
	
	return true
end

-- Check if a recipe is ready to claim
function CraftingMachines.IsRecipeReady(player: Player, craftingMachineId: string, recipeIndex: number): boolean
	local save = Saving.Get(player)
	if not save then
		return false
	end
	
	local machineSlots = save.CraftingMachines[craftingMachineId]
	if not machineSlots then
		return false
	end
	
	local recipeKey = tostring(recipeIndex)
	local slot = machineSlots[recipeKey]
	if not slot then
		return false
	end
	
	local currentTime = workspace:GetServerTimeNow()
	return currentTime >= slot.CompletionTime
end

-- Claim a completed recipe
function CraftingMachines.Claim(player: Player, craftingMachineId: string, recipeIndex: number): boolean
	local save = Saving.Get(player)
	if not save then
		return false
	end
	
	if not CraftingMachines.IsRecipeReady(player, craftingMachineId, recipeIndex) then
		return false
	end
	
	-- Check if inventory is full
	local inventorySize = save.PlotSave and save.PlotSave.Variables and save.PlotSave.Variables.InventorySize or 0
	local currentInventoryCount = #save.Inventory
	
	if currentInventoryCount >= inventorySize then
		Notifications.Message(player, "You need to make room in your inventory first!", {
			Color = Color3.fromRGB(255, 0, 0),
		})
		return false
	end
	
	local machineSlots = save.CraftingMachines[craftingMachineId]
	if not machineSlots then
		return false
	end
	
	local recipeKey = tostring(recipeIndex)
	local slot = machineSlots[recipeKey]
	if not slot then
		return false
	end
	
	-- Give the result fish
	local fishData = Fish.Give(player, slot.ResultFish)
	if fishData then
		local fishSchema = Directory.Fish[fishData.FishId]
		local displayName = fishSchema and fishSchema.DisplayName or fishData.FishId
		
		-- Force player to hold the crafted fish
		Fish.ForceHoldFish(player, fishData)
		
		local prefix = Functions.AnOrA(displayName)
		Notifications.Message(player, `You crafted {prefix} {displayName}!`, {
			Color = Color3.fromRGB(0, 255, 0),
		})
		
		-- Clear the slot
		save.CraftingMachines[craftingMachineId][recipeKey] = nil
		
		return true
	else
		Notifications.Message(player, "Failed to claim craft - inventory full?", {
			Color = Color3.fromRGB(255, 0, 0),
		})
		return false
	end
end

-- Network handlers
Network.Invoked("CraftingMachines_Craft", function(player: Player, craftingMachineId: string, recipeIndex: number)
	if typeof(craftingMachineId) ~= "string" or typeof(recipeIndex) ~= "number" then
		return false
	end
	
	return CraftingMachines.Craft(player, craftingMachineId, recipeIndex)
end)

Network.Invoked("CraftingMachines_Claim", function(player: Player, craftingMachineId: string, recipeIndex: number)
	if typeof(craftingMachineId) ~= "string" or typeof(recipeIndex) ~= "number" then
		return false
	end
	
	return CraftingMachines.Claim(player, craftingMachineId, recipeIndex)
end)

Network.Invoked("CraftingMachines_GetRecipeIngredients", function(player: Player, craftingMachineId: string, recipeIndex: number)
	if typeof(craftingMachineId) ~= "string" or typeof(recipeIndex) ~= "number" then
		return nil
	end
	
	return CraftingMachines.GetRecipeIngredients(craftingMachineId, recipeIndex)
end)

-- Send updated recipes to all players for a specific machine
local function broadcastRecipeUpdates(machineId: string)
	local schema = Directory.CraftingMachines[machineId]
	if not schema then return end
	
	-- Build recipe data for all recipes
	local recipes: {[number]: CraftingMachineTypes.recipe_ingredients_schema} = {}
	for recipeIndex = 1, #schema.Recipes do
		local recipeData = CraftingMachines.GetRecipeIngredients(machineId, recipeIndex)
		if recipeData then
			recipes[recipeIndex] = recipeData
		end
	end
	
	-- Send to all players
	Network.FireAll("CraftingMachines_RecipesUpdated", machineId, recipes)
end

-- Initialize current intervals for all machines
for machineId, schema in pairs(Directory.CraftingMachines) do
	currentIntervals[machineId] = getCurrentInterval(schema)
end

-- Check for interval changes and update recipes
task.spawn(function()
	while true do
		task.wait(1) -- Check every 10 seconds
		
		-- Check each machine individually
		for machineId, schema in pairs(Directory.CraftingMachines) do
			local newInterval = getCurrentInterval(schema)
			local oldInterval = currentIntervals[machineId]
			
			if newInterval ~= oldInterval then
				currentIntervals[machineId] = newInterval
				
				-- Broadcast updated recipes for this machine
				broadcastRecipeUpdates(machineId)
			end
		end
	end
end)

return CraftingMachines

