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
local NetworkClient = require(Library.Client.Network)

local player = Players.LocalPlayer
local shopIsSetup = false
local shopButtons = {}
local buttonConnections = {}
local increaseLuckUpdaterStarted = false
local serverLuckMultiplier: number = 1
local serverLuckTimeLeft: number = 0
local serverLuckLastSync: number = 0

-- Specialized: BestCoil purchase tile (Flame Coil)
local bestCoilInitialized = false
local bestCoilFrame: Frame?
local _bestCoilButton: GuiButton?
local FLAME_COIL_KEY = "Flame Coil"
local flameCoilProductId: number?

local function initServerLuckSync()
    task.spawn(function()
        local m, t = NetworkClient.Invoke("ServerLuck_Get")
        if typeof(m) == "number" then serverLuckMultiplier = m end
        if typeof(t) == "number" then serverLuckTimeLeft = t end
        serverLuckLastSync = workspace:GetServerTimeNow()
    end)
    NetworkClient.Fired("ServerLuck_Update", function(m: number, t: number)
        serverLuckMultiplier = m
        serverLuckTimeLeft = t
        serverLuckLastSync = workspace:GetServerTimeNow()
    end)
end

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
		
		if doesOwnGamepass(gamepassId) then
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

--// Specialized setup for IncreaseLuck panel
local function setupIncreaseLuck(scrollingFrame: Instance)
    local increaseFrame = scrollingFrame:FindFirstChild("IncreaseLuck")
    if not increaseFrame or not increaseFrame:IsA("Frame") then return end

    local luckMult = increaseFrame:FindFirstChild("LuckMult")
    local isActive = increaseFrame:FindFirstChild("IsActive")
    local buttons = increaseFrame:FindFirstChild("Buttons")
    local buyButton = buttons and buttons:FindFirstChild("BuyButton")
    local buyText = buyButton and buyButton:FindFirstChild("TextLabel")
    local clover = increaseFrame:WaitForChild("ToolImage"):WaitForChild("ImageLabel")::ImageLabel

    if buyButton and buyButton:IsA("GuiButton") then
        ButtonFX(buyButton)
    end

    local function getProductIdForState(mult: number): number?
        if mult <= 1 then
            local schema = ProductDirectory["2x Server Luck"]
            return schema and schema.ProductId or nil
        else
            local schema = ProductDirectory["4x Server Luck"]
            return schema and schema.ProductId or nil
        end
    end

    local function updatePriceLabel(productId: number?)
        if not (buyText and buyText:IsA("TextLabel")) then return end
        if not productId then
            buyText.Text = " ???"
            return
        end
        buyText.Text = " ???"
        task.spawn(function()
            local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
            if success and info and buyText and buyText:IsA("TextLabel") then
                buyText.Text = ` {info.PriceInRobux}`
            end
        end)
    end

    local function refresh()
        local mult = serverLuckMultiplier
        local derivedLeft = math.max(0, serverLuckTimeLeft - (workspace:GetServerTimeNow() - serverLuckLastSync))
        local timeLeft = math.floor(derivedLeft)

        if luckMult and luckMult:IsA("TextLabel") then
            if mult <= 1 then
                luckMult.Text = "1x -> 2x"
            elseif mult < 4 then
                luckMult.Text = "2x -> 4x"
            else
                luckMult.Text = "Maxed 4x!"
            end
        end

        if isActive and isActive:IsA("TextLabel") then
            if mult <= 1 then
                isActive.Text = "Activate!"
            else
                isActive.Text = Functions.FormatTime(timeLeft)
            end
        end

		if clover and clover:IsA("ImageLabel") then
			if mult == 1 then
				clover.Image = "rbxassetid://91670033702172"
			else
				clover.Image = "rbxassetid://130334998181902"
			end
		end

        local productId = getProductIdForState(mult)
        updatePriceLabel(productId)

        if buyButton and buyButton:IsA("GuiButton") and productId then
            if buttonConnections[buyButton] then
                buttonConnections[buyButton]:Disconnect()
                buttonConnections[buyButton] = nil
            end
            buttonConnections[buyButton] = buyButton.Activated:Connect(function()
                Marketplace.Prompt(player, productId, true)
            end)
        end
    end

    if not increaseLuckUpdaterStarted then
        increaseLuckUpdaterStarted = true
        task.spawn(function()
            while increaseFrame and increaseFrame.Parent do
                -- Request server resync periodically while open
                if TabController.GetCurrentTab() == "Shop" then
                    refresh()
                    -- backstop sync every 5s
                    if (workspace:GetServerTimeNow() - serverLuckLastSync) > 5 then
                        task.spawn(function()
                            local m, t = NetworkClient.Invoke("ServerLuck_Get")
                            if typeof(m) == "number" then serverLuckMultiplier = m end
                            if typeof(t) == "number" then serverLuckTimeLeft = t end
                            serverLuckLastSync = workspace:GetServerTimeNow()
                        end)
                    end
                end
                task.wait(1)
            end
            increaseLuckUpdaterStarted = false
        end)
    end
    refresh()
end

--// Specialized setup for the BestCoil tile (Flame Coil product outside the scrolling list)
local function setupBestCoil(shopGui: ScreenGui)
    if bestCoilInitialized then return end
    local frame = shopGui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return end

    local bc = frame:FindFirstChild("BestCoil")
    if not bc or not bc:IsA("Frame") then return end

    local coilImage = bc:FindFirstChild("CoilImage")
    local imageButton = coilImage and coilImage:FindFirstChild("ImageButton")
    if not (imageButton and imageButton:IsA("GuiButton")) then return end

    bestCoilInitialized = true
    bestCoilFrame = bc
    _bestCoilButton = imageButton
    flameCoilProductId = ProductCmds.GetProductId(FLAME_COIL_KEY)

    ButtonFX(imageButton)

    local priceLabel = bc:FindFirstChild("TextLabel")

    local function updatePriceLabel()
        if not (priceLabel and priceLabel:IsA("TextLabel")) then return end
        if not flameCoilProductId then
            priceLabel.Text = " ???"
            return
        end
        priceLabel.Text = " ???"
        task.spawn(function()
            local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, flameCoilProductId :: number, Enum.InfoType.Product)
            if success and info and priceLabel and priceLabel:IsA("TextLabel") then
                priceLabel.Text = ` {info.PriceInRobux}`
            end
        end)
    end

    local function refresh()
        local owned = ProductCmds.Owns(FLAME_COIL_KEY)
        if bestCoilFrame and bestCoilFrame:IsA("Frame") then
            bestCoilFrame.Visible = not owned
        end
        if not owned then
            if not flameCoilProductId then
                flameCoilProductId = ProductCmds.GetProductId(FLAME_COIL_KEY)
            end
            updatePriceLabel()
        end
    end

    if buttonConnections[imageButton] then
        buttonConnections[imageButton]:Disconnect()
        buttonConnections[imageButton] = nil
    end
    buttonConnections[imageButton] = imageButton.Activated:Connect(function()
        if not flameCoilProductId then
            flameCoilProductId = ProductCmds.GetProductId(FLAME_COIL_KEY)
        end

        updatePriceLabel()
        if flameCoilProductId then
            Marketplace.Prompt(player, flameCoilProductId :: number, true)
        end
    end)

    -- Ensure correct visibility on init
    refresh()

    -- Update when purchases land in save
    Save.Fired(function(key)
        if key == "Products" then
            refresh()
        end
    end)
end

--// Main setup function for the entire shop
local function setupShop()
	if shopIsSetup then return end -- Prevent re-running setup

	local shopGui = GUI.Shop()
	if not shopGui then return end
	
	local scrollingFrame = shopGui:WaitForChild("Frame"):WaitForChild("MainFrame"):WaitForChild("Content"):WaitForChild("ScrollingFrame")
	
	for _, descendant in ipairs(scrollingFrame:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			table.insert(shopButtons, descendant)
			ButtonFX(descendant)
			setupButton(descendant)
		end
	end

    setupIncreaseLuck(scrollingFrame)
    setupBestCoil(shopGui)
	
	task.delay(0.1, function()
		Functions.UpdateCanvasSize(scrollingFrame)
	end)
	
	shopIsSetup = true

    initServerLuckSync()
    setupIncreaseLuck(scrollingFrame)
end

-- Listen for when the shop tab is opened
TabController.Opened:Connect(function(tabId)
	if tabId == "Shop" then
		setupShop()
		local shopGui = GUI.Shop()
		if shopGui then
			local scrollingFrame = shopGui.Frame.MainFrame.Content.ScrollingFrame
			setupIncreaseLuck(scrollingFrame)
			setupBestCoil(shopGui)
		end
	end
end)

Save.Fired(function(key)
	if key == "Products" or key == "Gamepasses" then
		for _, button in ipairs(shopButtons) do
			setupButton(button)
		end
		local shopGui = GUI.Shop()
		if shopGui then
			local scrollingFrame = shopGui.Frame.MainFrame.Content.ScrollingFrame
			setupIncreaseLuck(scrollingFrame)
		end
	end
end) 

task.spawn(setupShop)