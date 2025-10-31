--!strict

--[[
	Manages the HalloweenCrafting GUI.
	Updates recipe information when the tab is opened.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local CraftingMachinesCmds = require(ReplicatedStorage.Game.Library.Client.CraftingMachinesCmds)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local Save = require(ReplicatedStorage.Library.Client.Save)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Functions = require(ReplicatedStorage.Library.Functions)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)

local CRAFTING_MACHINE_ID = "Halloween Crafting Machine"
local CRAFTING_EPOCH_START = 1761930000

local halloweenCraftingGui = GUI.HalloweenCrafting()
local contentFrame = halloweenCraftingGui.Frame.MainFrame.Content
local rightFrame = contentFrame.Right.Frame
local leftFrame = contentFrame.Left

local currentSelectedRecipe = 1
local craftingTimerThread: thread? = nil

-- Get the gradient templates
local godGradient = ReplicatedStorage.Assets:FindFirstChild("GodGradient")
local secretGradient = ReplicatedStorage.Assets:FindFirstChild("SecretGradient")
local rainbowGradient = ReplicatedStorage.Assets:FindFirstChild("RainbowGradientWrapped")
local purpleGradient = ReplicatedStorage.Assets.Gradients:FindFirstChild("PurpleUIGradient")
local grayGradient = ReplicatedStorage.Assets.Gradients:FindFirstChild("GrayUIGradient")

-- Helper function to set rarity gradient on a background element
local function setRarityGradient(backgroundElement: GuiObject, rarity: any)
	if not backgroundElement then return end
	
	-- Clear existing gradients
	for _, child in ipairs(backgroundElement:GetChildren()) do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end
	
	if rarity._id == "God" and godGradient then
		local gradient = godGradient:Clone()
		gradient.Parent = backgroundElement
	elseif rarity._id == "Secret" and secretGradient then
		local gradient = secretGradient:Clone()
		gradient.Parent = backgroundElement
	elseif rarity._id == "Mythical" and rainbowGradient then
		local gradient = rainbowGradient:Clone()
		gradient.Parent = backgroundElement
	else
		-- Create a simple gradient using the rarity color
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(rarity.Color)
		gradient.Parent = backgroundElement
	end
end

-- Update the CraftButton gradient and cost display (forward declared for updateLeftFrame)
local updateCraftButton: (number, any) -> ()

-- Update the Left frame with the selected recipe information
local function updateLeftFrame(recipeIndex: number)
	print(`[HalloweenCrafting] Updating left frame for recipe {recipeIndex}`)
	
	local craftData = CraftingMachinesCmds.GetCraftData(CRAFTING_MACHINE_ID, recipeIndex)
	
	if not craftData.RecipeIngredients or not craftData.RecipeIngredients.Result then
		warn(`[HalloweenCrafting] No recipe ingredients found for recipe {recipeIndex}`)
		return
	end
	
	local resultFish = craftData.RecipeIngredients.Result
	local fishSchema = Directory.Fish[resultFish.FishId]
	
	if not fishSchema then
		warn(`[HalloweenCrafting] Fish schema not found for {resultFish.FishId}`)
		return
	end
	
	-- Get the icon for the result fish
	local icon = fishSchema.Icon
	if fishSchema.MutationIcons and resultFish.Mutation then
		icon = fishSchema.MutationIcons[resultFish.Mutation] or fishSchema.Icon
	end
	
	-- Update SelectedFish frame
	local selectedFishFrame = leftFrame:FindFirstChild("SelectedFish")
	if selectedFishFrame then
		-- Hide when crafting, show when not crafting
		selectedFishFrame.Visible = not craftData.IsCrafting
		
		local selectedImageLabel = selectedFishFrame:FindFirstChild("ImageLabel")
		local selectedTitle = selectedFishFrame:FindFirstChild("Title")
		local selectedBackground = selectedFishFrame:FindFirstChild("Background")
		
		if selectedImageLabel and selectedImageLabel:IsA("ImageLabel") then
			selectedImageLabel.Image = icon
		end
		
		if selectedTitle and selectedTitle:IsA("TextLabel") then
			selectedTitle.Text = fishSchema.DisplayName
		end
		
		-- Set rarity gradient on the background
		if selectedBackground and fishSchema.Rarity then
			setRarityGradient(selectedBackground, fishSchema.Rarity)
		end
	end
	
	-- Update CraftingInProgress frame
	local craftingInProgressFrame = leftFrame:FindFirstChild("CraftingInProgress")
	if craftingInProgressFrame then
		craftingInProgressFrame.Visible = craftData.IsCrafting
		
		if craftData.IsCrafting then
			-- Get the fish being crafted from save data (not current recipe)
			local save = Save.Get()
			if save and save.CraftingMachines and save.CraftingMachines[CRAFTING_MACHINE_ID] then
				local recipeKey = tostring(recipeIndex)
				local slot = save.CraftingMachines[CRAFTING_MACHINE_ID][recipeKey]
				
				if slot and slot.ResultFish then
					local craftingFish = slot.ResultFish
					local craftingFishSchema = Directory.Fish[craftingFish.FishId]
					
					if craftingFishSchema then
						local progressImageLabel = craftingInProgressFrame:FindFirstChild("ImageLabel")
						local progressTitle = craftingInProgressFrame:FindFirstChild("Title")
						local rarityColorFrame = craftingInProgressFrame:FindFirstChild("RarityColor")
						
						-- Get the icon for the crafting fish
						local craftingIcon = craftingFishSchema.Icon
						if craftingFishSchema.MutationIcons and craftingFish.Mutation then
							craftingIcon = craftingFishSchema.MutationIcons[craftingFish.Mutation] or craftingFishSchema.Icon
						end
						
						if progressImageLabel and progressImageLabel:IsA("ImageLabel") then
							progressImageLabel.Image = craftingIcon
						end
						
						if progressTitle and progressTitle:IsA("TextLabel") then
							progressTitle.Text = craftingFishSchema.DisplayName
						end
						
						-- Set rarity color or gradient
						if rarityColorFrame and craftingFishSchema.Rarity then
							local rarity = craftingFishSchema.Rarity
							
							if rarity._id == "God" or rarity._id == "Secret" or rarity._id == "Mythical" then
								-- Use gradient for God/Secret/Mythical
								setRarityGradient(rarityColorFrame, rarity)
							else
								-- Use solid color for other rarities
								if rarityColorFrame:IsA("Frame") or rarityColorFrame:IsA("ImageLabel") or rarityColorFrame:IsA("ImageButton") then
									rarityColorFrame.BackgroundColor3 = rarity.Color
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- Update Crafting status text
	local selectedLabel = leftFrame:FindFirstChild("Selected")
	local timeLabel = leftFrame:FindFirstChild("Time")
	
	if selectedLabel and selectedLabel:IsA("TextLabel") then
		if craftData.IsCrafting then
			selectedLabel.Text = "Crafting"
		else
			selectedLabel.Text = "Selected"
		end
	end
	
	if timeLabel and timeLabel:IsA("TextLabel") then
		if craftData.IsCrafting then
			if craftData.IsReady then
				timeLabel.Text = "Complete!"
			elseif craftData.TimeRemaining then
				timeLabel.Text = `Craft complete in: {Functions.FormatTime(craftData.TimeRemaining)}`
			end
		elseif craftData.Recipe then
			timeLabel.Text = `Crafting time: {Functions.FormatTime(craftData.Recipe.CraftTime)}`
		end
	end
	
	-- Update CraftButton
	updateCraftButton(recipeIndex, craftData)
	
	-- Set up crafting timer if currently crafting
	local currentThread = coroutine.running()
	if craftingTimerThread and craftingTimerThread ~= currentThread then
		pcall(function()
			task.cancel(craftingTimerThread)
		end)
		craftingTimerThread = nil
	end
	
	if craftData.IsCrafting and not craftData.IsReady then
		-- Start a timer that updates every 0.5 seconds
		craftingTimerThread = task.spawn(function()
			local myThread = coroutine.running()
			while true do
				task.wait(0.5)
				
				-- Check if we're still on the same recipe and still crafting
				local currentCraftData = CraftingMachinesCmds.GetCraftData(CRAFTING_MACHINE_ID, currentSelectedRecipe)
				if not currentCraftData.IsCrafting or currentCraftData.IsReady or currentSelectedRecipe ~= recipeIndex then
					-- Clear our reference before updating to prevent self-cancel
					if craftingTimerThread == myThread then
						craftingTimerThread = nil
					end
					-- Update one final time and break
					updateLeftFrame(currentSelectedRecipe)
					break
				end
				
				-- Update the timer display
				if timeLabel and timeLabel:IsA("TextLabel") and currentCraftData.TimeRemaining then
					timeLabel.Text = `Craft complete in: {Functions.FormatTime(currentCraftData.TimeRemaining)}`
				end
				
				-- Update button in case it became ready
				updateCraftButton(currentSelectedRecipe, currentCraftData)
			end
		end)
	end
	
	-- Update Required ingredients
	local requiredFrame = leftFrame:FindFirstChild("Required")
	local requiredTextLabel = leftFrame:FindFirstChild("RequiredText")
	
	-- Hide Required elements when crafting, show when not crafting
	if requiredFrame then
		requiredFrame.Visible = not craftData.IsCrafting
	end
	if requiredTextLabel then
		requiredTextLabel.Visible = not craftData.IsCrafting
	end
	
	if requiredFrame then
		local template = requiredFrame:FindFirstChild("Template")
		if template then
			template.Visible = false
			
			-- Clear existing ingredient displays (except template and UIListLayout)
			for _, child in ipairs(requiredFrame:GetChildren()) do
				if child:IsA("Frame") and child ~= template then
					child:Destroy()
				end
			end
			
			-- Get ingredients and sort by MoneyPerSecond
			local ingredients = craftData.RecipeIngredients.Ingredients
			if ingredients then
				print(`[HalloweenCrafting] Updating {#ingredients} required ingredients`)
				
				local sortedIngredients = {}
				for _, ingredient in ipairs(ingredients) do
					local ingredientFishSchema = Directory.Fish[ingredient.FishId]
					if ingredientFishSchema then
						table.insert(sortedIngredients, {
							params = ingredient,
							schema = ingredientFishSchema,
							mps = ingredientFishSchema.MoneyPerSecond or 0,
						})
					else
						warn(`[HalloweenCrafting] Fish schema not found for ingredient: {ingredient.FishId}`)
					end
				end
				
				-- Sort by MoneyPerSecond
				table.sort(sortedIngredients, function(a, b)
					return a.mps < b.mps
				end)
				
				-- Create ingredient displays
				for i, ingredientData in ipairs(sortedIngredients) do
					local clone = template:Clone()
					clone.Name = `Ingredient{i}`
					clone.Visible = true
					
					local ingredientImageLabel = clone:FindFirstChild("ImageLabel")
					local ingredientTitle = clone:FindFirstChild("Title")
					local rarityColorFrame = clone:FindFirstChild("RarityColor")
					
					if ingredientImageLabel and ingredientImageLabel:IsA("ImageLabel") then
						local ingredientIcon = ingredientData.schema.Icon
						if ingredientData.schema.MutationIcons and ingredientData.params.Mutation then
							ingredientIcon = ingredientData.schema.MutationIcons[ingredientData.params.Mutation] or ingredientData.schema.Icon
						end
						ingredientImageLabel.Image = ingredientIcon
						print(`[HalloweenCrafting] Set ingredient {i} icon: {ingredientData.schema.DisplayName}`)
					end
					
					if ingredientTitle and ingredientTitle:IsA("TextLabel") then
						ingredientTitle.Text = ingredientData.schema.DisplayName
					end
					
					-- Set rarity color or gradient
					if rarityColorFrame and ingredientData.schema.Rarity then
						local rarity = ingredientData.schema.Rarity
						
						if rarity._id == "God" or rarity._id == "Secret" or rarity._id == "Mythical" then
							-- Use gradient for God/Secret/Mythical
							setRarityGradient(rarityColorFrame, rarity)
						else
							-- Use solid color for other rarities
							if rarityColorFrame:IsA("Frame") or rarityColorFrame:IsA("ImageLabel") or rarityColorFrame:IsA("ImageButton") then
								rarityColorFrame.BackgroundColor3 = rarity.Color
							end
						end
					end
					
					clone.Parent = requiredFrame
				end
			else
				warn("[HalloweenCrafting] No ingredients found in recipe data")
			end
		else
			warn("[HalloweenCrafting] Template not found in Required frame")
		end
	else
		warn("[HalloweenCrafting] Required frame not found in Left frame")
	end
end

-- Update the CraftButton gradient and cost display
updateCraftButton = function(recipeIndex: number, craftData: any)
	local craftButton = leftFrame:FindFirstChild("CraftButton")
	if not craftButton or not craftButton:IsA("ImageButton") then
		return
	end
	
	local textLabel = craftButton:FindFirstChild("TextLabel")
	
	-- Update button text based on state
	if textLabel and textLabel:IsA("TextLabel") then
		if craftData.IsCrafting then
			textLabel.Text = "Claim!"
		elseif craftData.Recipe then
			textLabel.Text = `${Functions.NumberShorten(craftData.Recipe.CraftCost)}`
		end
	end
	
	-- Determine button state
	local canInteract = false
	if craftData.IsCrafting then
		-- In crafting mode, can interact if ready to claim
		canInteract = craftData.IsReady
	else
		-- In craft mode, can interact if player can afford
		canInteract = CraftingMachinesCmds.CanCraft(CRAFTING_MACHINE_ID, recipeIndex)
	end
	
	-- Clear existing gradients
	for _, child in ipairs(craftButton:GetChildren()) do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end
	
	-- Add appropriate gradient
	if canInteract and purpleGradient then
		local gradient = purpleGradient:Clone()
		gradient.Parent = craftButton
	elseif not canInteract and grayGradient then
		local gradient = grayGradient:Clone()
		gradient.Parent = craftButton
	end
end

-- Handle CraftButton click
local function setupCraftButton()
	local craftButton = leftFrame:FindFirstChild("CraftButton")
	if not craftButton or not craftButton:IsA("ImageButton") then
		warn("[HalloweenCrafting] CraftButton not found")
		return
	end
	
	-- Add button effects
	ButtonFX(craftButton)
	
	-- Set up click handler
	craftButton.Activated:Connect(function()
		local craftData = CraftingMachinesCmds.GetCraftData(CRAFTING_MACHINE_ID, currentSelectedRecipe)
		
		if craftData.IsCrafting then
			-- In claiming mode
			if not craftData.IsReady then
				NotificationCmds.Message("You cannot claim this yet!", {
					Color = Color3.fromRGB(255, 0, 0),
				})
				return
			end
			
			-- Attempt to claim
			local success = CraftingMachinesCmds.Claim(CRAFTING_MACHINE_ID, currentSelectedRecipe)
			
			if success then
				-- Close the UI on successful claim
				TabController.CloseTab()
			end
		else
			-- In crafting mode
			local canCraft = CraftingMachinesCmds.CanCraft(CRAFTING_MACHINE_ID, currentSelectedRecipe)
			
			if not canCraft then
				NotificationCmds.Message("You don't have the required materials to craft!", {
					Color = Color3.fromRGB(255, 0, 0),
				})
				return
			end
			
			-- Attempt to craft
			local success = CraftingMachinesCmds.Craft(CRAFTING_MACHINE_ID, currentSelectedRecipe)
			
			if success then
				-- Get the craft data to show time and fish name				
				-- Update the UI to reflect the new crafting state
				updateLeftFrame(currentSelectedRecipe)
			end
		end
	end)
end

-- Update a single recipe slot with the result fish information
local function updateRecipeSlot(slotIndex: number)
	local slotButton = rightFrame:FindFirstChild(tostring(slotIndex))
	if not slotButton then
		warn(`[HalloweenCrafting] Slot button {slotIndex} not found`)
		return
	end
	
	local imageLabel = slotButton:FindFirstChild("ImageLabel")
	local titleLabel = slotButton:FindFirstChild("Title")
	local backgroundLabel = slotButton:FindFirstChild("Background")
	
	if not imageLabel or not imageLabel:IsA("ImageLabel") then
		warn(`[HalloweenCrafting] ImageLabel not found in slot {slotIndex}`)
		return
	end
	
	if not titleLabel or not titleLabel:IsA("TextLabel") then
		warn(`[HalloweenCrafting] Title not found in slot {slotIndex}`)
		return
	end
	
	-- Get the recipe data
	local craftData = CraftingMachinesCmds.GetCraftData(CRAFTING_MACHINE_ID, slotIndex)
	
	if not craftData.RecipeIngredients or not craftData.RecipeIngredients.Result then
		-- No recipe data available yet
		imageLabel.Image = ""
		titleLabel.Text = "Loading..."
		return
	end
	
	local resultFish = craftData.RecipeIngredients.Result
	local fishSchema = Directory.Fish[resultFish.FishId]
	
	if not fishSchema then
		warn(`[HalloweenCrafting] Fish schema not found for {resultFish.FishId}`)
		imageLabel.Image = ""
		titleLabel.Text = "Unknown Fish"
		return
	end
	
	-- Set the image and title
	local icon = fishSchema.Icon
	
	-- Check for mutation-specific icons
	if fishSchema.MutationIcons and resultFish.Mutation then
		icon = fishSchema.MutationIcons[resultFish.Mutation] or fishSchema.Icon
	end
	
	imageLabel.Image = icon
	titleLabel.Text = fishSchema.DisplayName
	
	-- Set rarity gradient on the background
	if backgroundLabel and fishSchema.Rarity then
		setRarityGradient(backgroundLabel, fishSchema.Rarity)
	end
end

-- Set up button click handlers for recipe selection
local function setupRecipeButtons()
	local schema = Directory.CraftingMachines[CRAFTING_MACHINE_ID]
	if not schema then
		warn("[HalloweenCrafting] No crafting machine schema found!")
		return
	end
	
	print(`[HalloweenCrafting] Setting up {#schema.Recipes} recipe buttons`)
	
	for i = 1, #schema.Recipes do
		local slotButton = rightFrame:FindFirstChild(tostring(i))
		if slotButton then
			if slotButton:IsA("ImageButton") then
				-- Ensure button is active and can receive input
				slotButton.Active = true
				slotButton.AutoButtonColor = true
				
				-- Add button effects
				ButtonFX(slotButton)
				
				-- Set up click handler
				slotButton.Activated:Connect(function()
					print(`[HalloweenCrafting] Recipe {i} clicked`)
					currentSelectedRecipe = i
					updateLeftFrame(i)
				end)
				
				print(`[HalloweenCrafting] Setup button {i} - Active: {slotButton.Active}, ZIndex: {slotButton.ZIndex}`)
			else
				warn(`[HalloweenCrafting] Slot {i} is not an ImageButton, it's a {slotButton.ClassName}`)
			end
		else
			warn(`[HalloweenCrafting] Slot button {i} not found in Right/Frame`)
		end
	end
end

-- Update all recipe slots
local function updateAllRecipes()
	local schema = Directory.CraftingMachines[CRAFTING_MACHINE_ID]
	if not schema then
		warn(`[HalloweenCrafting] Crafting machine schema not found for {CRAFTING_MACHINE_ID}`)
		return
	end
	
	-- Update each recipe slot
	for i = 1, #schema.Recipes do
		updateRecipeSlot(i)
	end
	
	-- Update the left frame with the currently selected recipe
	updateLeftFrame(currentSelectedRecipe)
end

-- Initialize the GUI
local function initialize()
	setupRecipeButtons()
	setupCraftButton()
	
	-- Set default selected recipe to 1
	currentSelectedRecipe = 1
	updateAllRecipes()
end

-- Update when the tab is opened
TabController.Opened:Connect(function(tabId)
	if tabId == "HalloweenCrafting" then
		updateAllRecipes()
	end
end)

-- Update when save data changes
Save.SaveAdded:Connect(function()
	if TabController.GetCurrentTab() == "HalloweenCrafting" then
		updateAllRecipes()
	end
end)

Save.Fired(function(key)
	if key == "CraftingMachines" and TabController.GetCurrentTab() == "HalloweenCrafting" then
		updateAllRecipes()
	end
end)

-- Update when recipes are updated (every 3 hours or when loaded)
CraftingMachinesCmds.RecipesUpdated:Connect(function()
	if TabController.GetCurrentTab() == "HalloweenCrafting" then
		updateAllRecipes()
	end
end)

-- Initialize the GUI
initialize()

-- Set up HalloweenCraftingBillboard timers
TagHook("HalloweenCraftingBillboard", function(instance: Instance)
	if not instance:IsA("BillboardGui") and not instance:IsA("SurfaceGui") then
		-- Try to find BillboardGui child
		local billboardGui = instance:FindFirstChildOfClass("BillboardGui") or instance:FindFirstChildOfClass("SurfaceGui")
		if not billboardGui then
			return function() end
		end
		instance = billboardGui
	end
	
	local refreshInLabel = instance:FindFirstChild("RefreshIn")
	if not refreshInLabel or not refreshInLabel:IsA("TextLabel") then
		warn("[HalloweenCrafting] RefreshIn TextLabel not found in billboard")
		return function() end
	end
	
	-- Get the crafting machine schema
	local schema = Directory.CraftingMachines[CRAFTING_MACHINE_ID]
	if not schema then
		warn("[HalloweenCrafting] No schema found for billboard")
		return function() end
	end
	
	-- Function to calculate time until next refresh
	local function getTimeUntilRefresh(): number
		local currentTime = workspace:GetServerTimeNow()
		local elapsedTime = currentTime - CRAFTING_EPOCH_START
		local currentInterval = math.floor(elapsedTime / schema.RecipeResetTime)
		local nextIntervalStart = CRAFTING_EPOCH_START + ((currentInterval + 1) * schema.RecipeResetTime)
		local timeRemaining = nextIntervalStart - currentTime
		return math.max(0, timeRemaining)
	end
	
	-- Update the label
	local function updateLabel()
		local timeRemaining = getTimeUntilRefresh()
		refreshInLabel.Text = `Refreshes in {Functions.FormatTime(timeRemaining)}`
	end
	
	-- Initial update
	updateLabel()
	
	-- Update every 0.5 seconds
	local updateThread = task.spawn(function()
		while true do
			task.wait(0.5)
			updateLabel()
		end
	end)
	
	-- Cleanup function
	return function()
		if updateThread then
			task.cancel(updateThread)
		end
	end
end)

