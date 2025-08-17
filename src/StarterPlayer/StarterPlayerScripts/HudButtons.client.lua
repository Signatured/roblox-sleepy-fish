--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local TabController = require(ReplicatedStorage.Library.Client.TabController)

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
			TabController.OpenTab("Tools")
		end)
	end

	if indexButton and indexButton:IsA("GuiButton") then
		ButtonFX(indexButton)
	end
end

setup()

return {}


