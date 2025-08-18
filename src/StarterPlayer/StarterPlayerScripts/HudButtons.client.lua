--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function setup()
	local mainGui = GUI.Main()
	local sideLeft = mainGui:FindFirstChild("SideLeft")
	if not sideLeft then
		warn("HudButtons: Could not find 'SideLeft' in Main gui")
		return
	end

	local buyButton = sideLeft:FindFirstChild("BuyButton")
	local indexButton = sideLeft:FindFirstChild("IndexButton")

	if buyButton and buyButton:IsA("GuiButton") then
		ButtonFX(buyButton)
		buyButton.Activated:Connect(function()
			if TabController.GetCurrentTab() ~= "Tools" then
				TabController.OpenTab("Tools")
			else
				TabController.CloseTab()
			end
		end)
	end

	if indexButton and indexButton:IsA("GuiButton") then
		ButtonFX(indexButton)
	end

	local sideRight = mainGui:FindFirstChild("SideRight")
	if not sideRight then
		warn("HudButtons: Could not find 'SideRight' in Main gui")
	else
		local multiButton = sideRight:FindFirstChild("MultiButton")
		if multiButton and multiButton:IsA("GuiButton") then
			ButtonFX(multiButton)
			multiButton.Activated:Connect(function()
				local product = getMultiProuct()
				if product then
					Marketplace.Prompt(player, product.ProductId, true)
				end
			end)
		end
	end
end

ClientPlot.OnLocalAndCreated(function(plot: ClientPlot.Type)
	setup()

	plot:SaveChanged("PaidIndex"):Connect(function(paidIndex: number)
		if paidIndex == 3 then
			local mainGui = GUI.Main()
			local sideRight = mainGui:FindFirstChild("SideRight")::Frame
			local multiButton = sideRight:FindFirstChild("MultiButton")::GuiButton
			
			multiButton.Visible = false
		end
	end)
end)