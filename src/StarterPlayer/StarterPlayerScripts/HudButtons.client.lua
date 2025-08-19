--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)
local ClientPlot = require(ReplicatedStorage.Plot.ClientPlot)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)

local player = game.Players.LocalPlayer

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
	textLabel.Text = " ???"
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

local function setup(plot: ClientPlot.Type)
	local paidIndex = plot:Save("PaidIndex")::number
	local mainGui = GUI.Main()
	local sideLeft = mainGui:FindFirstChild("SideLeft")
	if not sideLeft then
		warn("HudButtons: Could not find 'SideLeft' in Main gui")
		return
	end

	local shopButton = sideLeft:FindFirstChild("ShopButton")
	local indexButton = sideLeft:FindFirstChild("IndexButton")

	if shopButton and shopButton:IsA("GuiButton") then
		ButtonFX(shopButton)
		shopButton.Activated:Connect(function()
			TabController.OpenTab("Shop")
		end)
	end

	if indexButton and indexButton:IsA("GuiButton") then
		ButtonFX(indexButton)
	end

	local sideRight = mainGui:FindFirstChild("SideRight")
	if not sideRight then
		warn("HudButtons: Could not find 'SideRight' in Main gui")
	elseif paidIndex == 3 then
		hideMultiFrame()
	else
		local multiFrame = sideRight:FindFirstChild("Frame")::Frame
		local multiButton = multiFrame:FindFirstChild("MultiButton")
		local multiText = multiFrame:FindFirstChild("MultiText")
		if multiButton and multiButton:IsA("GuiButton") then
			ButtonFX(multiButton)
			multiButton.Activated:Connect(function()
				local product = getMultiProuct()
				if product then
					Marketplace.Prompt(player, product.ProductId, true)
				end
			end)
		end
		if multiText and multiText:IsA("TextLabel") then
			local product = Products[`Multi Tier {paidIndex + 1}`]

			if product then
				updatePriceLabel(multiText, product.ProductId)
			end
		end
	end
end

ClientPlot.OnLocalAndCreated(function(plot: ClientPlot.Type)
	setup(plot)

	plot:SaveChanged("PaidIndex"):Connect(function(paidIndex: number)
		if paidIndex == 3 then
			hideMultiFrame()
		end
	end)
end)