--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Framework modules
local Client = require(ReplicatedStorage.Library.Client)
local Save = Client.Save
local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local Functions = require(ReplicatedStorage.Library.Functions)
local GUIFX = Client.GUIFX
local ClientPlot = require(ReplicatedStorage.Plot.ClientPlot)

-- UI Components
local MainGui = GUI.Main()
local CashLabel = MainGui.BottomLeft.Desc:WaitForChild("Cash")::TextLabel
local uiScale = CashLabel:FindFirstChildOfClass("UIScale")::UIScale

local currenyMoney = 0

local function getUIScale(): UIScale?
    local uiScale = MainGui.BottomLeft.Desc:FindFirstChild("Cash_odometerGUIFX"):FindFirstChildOfClass("UIScale")::UIScale
    if uiScale then
        return uiScale
    end
    return nil
end

--// Updates the text label with the formatted coin amount
local function updateCoinsDisplay(newAmount: number)
	if newAmount then
		CashLabel.Text = `${Functions.NumberShorten(newAmount)}`

        local uiScale = getUIScale()
        if uiScale then
            uiScale.Scale = 1.1

            Functions.Tween(
                uiScale,
                { Scale = 1 },
                { "Exponential", "In", 0.2 }::{any}
		    )
        end
	end
end

--// Set up the button's functionality
GUIFX.Odometer(CashLabel, 0.5)

ClientPlot.Created:Connect(function(plot)
    if not plot:IsLocal() then
        return
    end

    local money = plot:Save("Money")
    if money then
        currenyMoney = money
        updateCoinsDisplay(money)
    end

	plot:SaveChanged("Money"):Connect(function(value: number)
		local newAmount = value
		local oldAmount = currenyMoney
		currenyMoney = newAmount

		updateCoinsDisplay(newAmount)
		if newAmount > oldAmount then
			local diff = newAmount - oldAmount
			-- GUIFX.CoinsPopup(diff)
		end
	end)
end)