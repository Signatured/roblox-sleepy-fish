--!strict

-- This script manages the Shop GUI, including setting up product buttons
-- and handling purchase prompts.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Framework Modules
local Library = ReplicatedStorage:WaitForChild("Library")
local GUI = require(game.ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(Library.Client.TabController)
local Marketplace = require(Library.Marketplace)
local ButtonFX = require(Library.Client.GUIFX.ButtonFX)
local ProductDirectory = require(ReplicatedStorage.Game.Library.Directory.Products)
local GamepassDirectory = require(ReplicatedStorage.Game.Library.Directory.Gamepasses)
local ProductCmds = require(Library.Client.ProductCmds)
local Save = require(Library.Client.Save)
local Functions = require(Library.Functions)

local player = Players.LocalPlayer
local shopIsSetup = false
local shopButtons = {}
local buttonConnections = {}

local function doesOwnGamepass(gamepassId: number): boolean
	local saveData = Save.Get()
	if not saveData or not saveData.Gamepasses then
		return false
	end
	return saveData.Gamepasses[tostring(gamepassId)] == true
end

--// Sets up a single button, determining if it's a product or gamepass
local function setupButton(button: GuiButton)
	if not button:IsA("GuiButton") then return end
	
	if buttonConnections[button] then
		buttonConnections[button]:Disconnect()
		buttonConnections[button] = nil
	end

	local id = button:GetAttribute("Id")
	if not id or typeof(id) ~= "string" then
		-- No attribute, so we don't need to warn. Just ignore it.
		return
	end

	local gamepassSchema = GamepassDirectory[id]
	if gamepassSchema then
		local gamepassId = gamepassSchema.GamepassId
		local textLabel = button:FindFirstChild("TextLabel")
		
        print("fired1", gamepassId)
		if doesOwnGamepass(gamepassId) then
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = "Owned!"
			end
			button.AutoButtonColor = false
			button.Activated:Connect(function() end)

            print("fired2", gamepassId)
		else
            print("fired3", gamepassId)
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = " ???" -- Loading state
			end

			task.spawn(function()
				local success, productInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, gamepassId, Enum.InfoType.GamePass)
				if button and button.Parent and textLabel and textLabel:IsA("TextLabel") then
					if success and productInfo then
						textLabel.Text = ` {productInfo.PriceInRobux}`
					end
				end
			end)

			buttonConnections[button] = button.Activated:Connect(function()
				Marketplace.Prompt(player, gamepassId, false) -- false for Gamepass
			end)
		end
		return
	end

	local productSchema = ProductDirectory[id]
	if productSchema then
		local productId = productSchema.ProductId
		local textLabel = button:FindFirstChild("TextLabel")
		
		if productSchema.OneTimePurchase and ProductCmds.Owns(id) then
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = "Owned!"
			end
			button.AutoButtonColor = false
			button.Activated:Connect(function() end)
		else
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = " ???" -- Loading state
			end
			
			task.spawn(function()
				local success, productInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
				if button and button.Parent and textLabel and textLabel:IsA("TextLabel") then -- Check if button still exists
					if success and productInfo then
						textLabel.Text = ` {productInfo.PriceInRobux}`
					end
				end
			end)
			
			buttonConnections[button] = button.Activated:Connect(function()
				Marketplace.Prompt(player, productId, true) -- true for Developer Product
			end)
		end
		return
	end

	warn(`[Shop] Could not find a matching Gamepass or Product for Id: '{id}' on button '{button:GetFullName()}'`)
end

--// Main setup function for the entire shop
local function setupShop()
	if shopIsSetup then return end -- Prevent re-running setup

	local shopGui = GUI.Shop()
	if not shopGui then return end
	
	local scrollingFrame = shopGui:WaitForChild("Frame"):WaitForChild("Container"):WaitForChild("MainFrame"):WaitForChild("Content"):WaitForChild("ScrollingFrame")
	
	for _, descendant in ipairs(scrollingFrame:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			table.insert(shopButtons, descendant)
			ButtonFX(descendant)
			setupButton(descendant)
		end
	end
	
	task.delay(0.1, function()
		-- Functions.UpdateCanvasSize(scrollingFrame)
	end)
	
	shopIsSetup = true
end

-- Listen for when the shop tab is opened
TabController.Opened:Connect(function(tabId)
	if tabId == "Shop" then
		setupShop()
	end
end)

Save.Fired(function(key)
	if key == "Products" or key == "Gamepasses" then
		for _, button in ipairs(shopButtons) do
			setupButton(button)
		end
	end
end) 

task.spawn(setupShop)