--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local SocialService = game:GetService("SocialService")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local ScaleComposer = require(ReplicatedStorage.Library.Client.GUIFX.ScaleComposer)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)
local ClientPlot = require(ReplicatedStorage.Plot.ClientPlot)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local GetRobuxPrice = require(ReplicatedStorage.Library.Functions.GetRobuxPrice)
local ProductCmds = require(ReplicatedStorage.Library.Client.ProductCmds)
local Network = require(ReplicatedStorage.Library.Client.Network)

local player = game.Players.LocalPlayer

-- Products to display in the rotating showcase (in order)
local ROTATING_PRODUCT_NAMES = {
	"Starter Pack",
	"Expert Pack",
	"Galaxy Coil",
	"Magic Carpet",
}

-- Optional per-product default scale (multiplier). Missing entries default to 1.
local ROTATING_PRODUCT_BASE_SCALE: {[string]: number} = {
	["Starter Pack"] = 1.5,
	["Expert Pack"] = 1.5,
	["Galaxy Coil"] = 1.0,
	["Magic Carpet"] = 1.0,
}

local function getMultiProuct(): Products.dir_schema?
	local plot = ClientPlot.GetLocal()
	if not plot then
		return nil
	end

	local paidIndex = plot:Save("PaidIndex")::number
	if not paidIndex then
		return nil
	end

	local product = Products[`Multi Tier {paidIndex + 1}`]
	return product
end

local function updatePriceLabel(textLabel: TextLabel, productId: number?)
	if not productId then
		textLabel.Text = " ???"
		return
	end
	-- textLabel.Text = " ???"
	task.spawn(function()
		local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
		if success and info and textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = ` {info.PriceInRobux}`
		end
	end)
end

local function hideMultiFrame()
	local mainGui = GUI.Main()
	local sideRight = mainGui:FindFirstChild("SideRight")
	if not sideRight then
		warn("HudButtons: Could not find 'SideRight' in Main gui")
	end

	local multiFrame = sideRight:FindFirstChild("Frame")::Frame
	multiFrame.Visible = false
end

local function updateMultiText(paidIndex: number)
	local mainRight = GUI.MainRight()
	local sideRight = mainRight:FindFirstChild("SideRight")
	if not sideRight then
		warn("HudButtons: Could not find 'SideRight' in Main gui")
	end
	
	local multiFrame = sideRight:FindFirstChild("Frame")::Frame
	local multiText = multiFrame:FindFirstChild("MultiText")
	if multiText and multiText:IsA("TextLabel") then
		local product = Products[`Multi Tier {paidIndex + 1}`]
		if product then
			updatePriceLabel(multiText, product.ProductId)
		end
	end
end

local function setup(plot: ClientPlot.Type)
	local paidIndex = plot:Save("PaidIndex")::number
	local mainGui = GUI.Main()
	local mainRight = GUI.MainRight()
	local sideLeft = mainGui:FindFirstChild("SideLeft")
	if not sideLeft then
		warn("HudButtons: Could not find 'SideLeft' in Main gui")
		return
	end

	local shopButton = sideLeft:FindFirstChild("ShopButton")
	local indexButton = sideLeft:FindFirstChild("IndexButton")
	local toolsButton = sideLeft:FindFirstChild("ToolsButton")

	if shopButton and shopButton:IsA("GuiButton") then
		ButtonFX(shopButton)
		shopButton.Activated:Connect(function()
			local current = TabController.GetCurrentTab()
			if current == "Shop" then
				TabController.CloseTab()
			else
				TabController.OpenTab("Shop")
			end
		end)
	end

	if indexButton and indexButton:IsA("GuiButton") then
		ButtonFX(indexButton)
		indexButton.Activated:Connect(function()
			local current = TabController.GetCurrentTab()
			if current == "Index" then
				TabController.CloseTab()
			else
				TabController.OpenTab("Index")
			end
		end)
	end

	if toolsButton and toolsButton:IsA("GuiButton") then
		ButtonFX(toolsButton)
		toolsButton.Activated:Connect(function()
			local current = TabController.GetCurrentTab()
			if current == "Tools" then
				TabController.CloseTab()
			else
				TabController.OpenTab("Tools")
			end
		end)
	end

	local sideRight = mainRight:FindFirstChild("SideRight")
	if not sideRight then
		warn("HudButtons: Could not find 'SideRight' in Main gui")
	elseif paidIndex == 3 then
		hideMultiFrame()
	else
		local multiFrame = sideRight:FindFirstChild("Frame")::Frame
		local multiButton = multiFrame:FindFirstChild("MultiButton")
		if multiButton and multiButton:IsA("GuiButton") then
			ButtonFX(multiButton)
			multiButton.Activated:Connect(function()
				local product = getMultiProuct()
				if product then
					Marketplace.Prompt(player, product.ProductId, true)
				end
			end)
		end
		updateMultiText(paidIndex)
	end

	-- Settings button in SideBottom
	local sideBottom = mainGui:FindFirstChild("SideBottom")
	if sideBottom and sideBottom:IsA("Frame") then
		local settingsFrame = sideBottom:FindFirstChild("Settings")
		local settingsButton = settingsFrame and settingsFrame:FindFirstChild("Button")
		if settingsButton and settingsButton:IsA("GuiButton") then
			ButtonFX(settingsButton)
			settingsButton.Activated:Connect(function()
				-- Toggle Settings tab using TabController
				local current = TabController.GetCurrentTab()
				if current == "Settings" then
					TabController.CloseTab()
				else
					TabController.OpenTab("Settings")
				end
			end)
		end

		local friendFrame = sideBottom:FindFirstChild("Friend")
		local friendButton = friendFrame and friendFrame:FindFirstChild("Button")
		if friendButton and settingsButton:IsA("GuiButton") then
			ButtonFX(friendButton)
			friendButton.Activated:Connect(function()
				pcall(function()
					SocialService:PromptGameInvite(player)
				end)
			end)
		end
	end

	-- MoreSpaceButton setup
	if sideRight and sideRight:IsA("Frame") then
		-- SleepPurchase button at Main/SideRight/SleepPurchase/Frame/ImageButton
		local sleepPurchase = sideRight:FindFirstChild("SleepPurchase")
		if sleepPurchase and sleepPurchase:IsA("Frame") then
			local purchaseFrame = sleepPurchase:FindFirstChild("Frame")
			local imageButton = purchaseFrame and purchaseFrame:FindFirstChild("ImageButton")
			if imageButton and imageButton:IsA("GuiButton") then
				ButtonFX(imageButton)
				imageButton.Activated:Connect(function()
					local product = Products["Sleep Fish"]
					if product then
						task.spawn(function()
							Network.Fire("ClickedProduct", product._id)
						end)
						Marketplace.Prompt(player, product.ProductId, true)
					end
				end)
			end
		end

		local moreSpaceButton = sideRight:FindFirstChild("MoreSpaceButton")
		if moreSpaceButton and moreSpaceButton:IsA("GuiButton") then
			ButtonFX(moreSpaceButton)
			moreSpaceButton.Activated:Connect(function()
				local product = Products["More Space"]
				if product then
					Marketplace.Prompt(player, product.ProductId, true)
				end
			end)

			-- visibility updater
			-- task.spawn(function()
			-- 	while sideRight and sideRight.Parent do
			-- 		local invLimit = plot:Save("InventorySize")::number?
			-- 		local save = Save.Get()
			-- 		local inv = (save and save.Inventory) or {}
			-- 		local isFull = (type(inv) == "table") and invLimit ~= nil and #inv >= (invLimit :: number)

			-- 		if invLimit > GameSettings.MaxInventory then
			-- 			isFull = false
			-- 		end

			-- 		moreSpaceButton.Visible = isFull == true
			-- 		task.wait(0.5)
			-- 	end
			-- end)
		end

		-- RotatingProducts setup
		local rotatingProducts = sideRight:FindFirstChild("RotatingProducts")
		if rotatingProducts and rotatingProducts:IsA("Frame") then
			local title = rotatingProducts:FindFirstChild("Title")
			local priceLabel = rotatingProducts:FindFirstChild("Price")
			local frame = rotatingProducts:FindFirstChild("Frame")
			local imageButton = frame and frame:FindFirstChild("ImageButton")
			if imageButton and imageButton:IsA("ImageButton") then
				-- Button feedback for rotating product button
				ButtonFX(imageButton)
				-- Build and maintain a validated list of product keys to rotate through (excludes owned one-time packs)
				local function buildRotationKeys(): {string}
					local keys = {}
					local ownsStarter = ProductCmds.Owns("Starter Pack")
					local ownsExpert = ProductCmds.Owns("Expert Pack")
					for _, name in ipairs(ROTATING_PRODUCT_NAMES) do
						local schema = Products[name]
						if schema then
							local skip = false
							if name == "Starter Pack" then
								-- Hide Starter Pack if already owned
								skip = ownsStarter
							elseif name == "Expert Pack" then
								-- Show Expert Pack only if Starter is owned and Expert not yet owned
								skip = (not ownsStarter) or ownsExpert
							else
								-- Other products: no special gating here
								skip = false
							end
							if not skip then
								table.insert(keys, name)
							end
						else
							warn("HudButtons: Rotating product not found in Products: " .. tostring(name))
						end
					end
					return keys
				end

				local rotationKeys = buildRotationKeys()
				if #rotationKeys == 0 then
					rotatingProducts.Visible = false
					return
				end

				local composer = ScaleComposer.Get(imageButton)
				composer:SetFactor("RotationSwap", 1)

				local idx = 1
				local function applyProduct()
					if idx < 1 or idx > #rotationKeys then idx = 1 end
					local name = rotationKeys[idx]
					local product = Products[name]
					if not product then
						return
					end

					-- Update title
					if title and title:IsA("TextLabel") then
						title.Text = product.DisplayName or name
					end

					-- Update price
					if priceLabel and priceLabel:IsA("TextLabel") then
						local price = GetRobuxPrice(product.ProductId, true)
						if price then
							priceLabel.Text = `{price}`
						else
							priceLabel.Text = "???"
						end
					end

					-- Update image
					imageButton.Image = product.Icon or imageButton.Image

					-- Apply default base scale for this product (composes with swap factor)
					local base = ROTATING_PRODUCT_BASE_SCALE[name]
					if typeof(base) ~= "number" then base = 1 end
					composer:SetFactor("RotationBase", base)
				end

				local function swapToNext()
					-- Rebuild list to reflect newly purchased packs
					rotationKeys = buildRotationKeys()
					if #rotationKeys == 0 then
						rotatingProducts.Visible = false
						return
					end
					idx += 1
					if idx > #rotationKeys then idx = 1 end
					-- Shrink almost to zero, swap, then grow back with Back easing
					composer:SetFactor("RotationSwap", 1e-4)
					applyProduct()
					local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					composer:TweenFactor("RotationSwap", 1, tweenInfo)
				end

				-- Initialize with first product
				applyProduct()
				-- Ensure scale is normal at start
				composer:SetFactor("RotationSwap", 1)

				-- Cycle every 20 seconds
				task.spawn(function()
					while rotatingProducts and rotatingProducts.Parent do
						task.wait(20)
						swapToNext()
					end
				end)

				-- Button behavior: purchase on click
				imageButton.Activated:Connect(function()
					local name = rotationKeys[idx]
					local product = Products[name]
					if product then
						task.spawn(function()
							Network.Fire("ClickedProduct", product._id)
						end)
						Marketplace.Prompt(player, product.ProductId, true)
					end
				end)
			end
		end
	end
end

ClientPlot.OnLocalAndCreated(function(plot: ClientPlot.Type)
	setup(plot)

	plot:SaveUpdated("PaidIndex"):Connect(function(paidIndex: number)
		if paidIndex == 3 then
			hideMultiFrame()
		else
			updateMultiText(paidIndex)
		end
	end)
end)