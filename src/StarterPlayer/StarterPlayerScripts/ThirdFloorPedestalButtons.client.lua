--!strict

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local Functions = require(game.ReplicatedStorage.Library.Functions)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local Message = require(game.ReplicatedStorage.Library.Client.Message)
local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)

-- Configurable bounce tween settings
local BUTTON_TWEEN_TOTAL_TIME = 0.3 -- seconds for full down-and-up cycle
local BUTTON_TWEEN_DEPTH = 0.2 -- studs to move down

local FLOOR_ID = 2 -- Floor 3 (ExtraFloors = 2)
local TOTAL_PEDESTAL_BUTTONS = 6

type ButtonData = {
	plot: ClientPlot.Type,
	buttonId: number,
	button: BasePart,
	model: Model,
	subtitle: TextLabel,
	price: number,
	pedestalGroupsConnection: any?,
	moneyConnection: any?,
}

local activeButtons: { [ClientPlot.Type]: {ButtonData} } = {}

local function playButtonBounce(buttonPart: BasePart)
	if not buttonPart or not buttonPart.Parent then
		return
	end
	if buttonPart:GetAttribute("_ButtonTweenActive") then
		return
	end
	buttonPart:SetAttribute("_ButtonTweenActive", true)

	local startPosition = buttonPart.Position
	local downPosition = startPosition - Vector3.new(0, BUTTON_TWEEN_DEPTH, 0)
	local halfDuration = BUTTON_TWEEN_TOTAL_TIME / 2
	local tweenInfo = TweenInfo.new(halfDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	task.spawn(function()
		-- Down
		local t1 = Functions.Tween(buttonPart, { Position = downPosition }, tweenInfo)
		if t1 and t1.Completed then
			t1.Completed:Wait()
		end
		-- Up
		if buttonPart.Parent then
			local t2 = Functions.Tween(buttonPart, { Position = startPosition }, tweenInfo)
			if t2 and t2.Completed then
				t2.Completed:Wait()
			end
		end
		buttonPart:SetAttribute("_ButtonTweenActive", false)
	end)
end

local function destroyButton(buttonData: ButtonData)
	-- Disconnect listeners
	if buttonData.pedestalGroupsConnection then
		pcall(function()
			buttonData.pedestalGroupsConnection:Disconnect()
		end)
		buttonData.pedestalGroupsConnection = nil
	end
	
	if buttonData.moneyConnection then
		pcall(function()
			buttonData.moneyConnection:Disconnect()
		end)
		buttonData.moneyConnection = nil
	end

	-- Destroy the model
	if buttonData.model and buttonData.model.Parent then
		buttonData.model:Destroy()
	end
end

local function updateButtonVisibility(plot: ClientPlot.Type)
	local buttons = activeButtons[plot]
	if not buttons then
		return
	end
	
	local extraFloors = plot:Save("ExtraFloors") or 0
	local pedestalGroupsUnlocked = plot:Save("PedestalGroupsUnlocked") or 0
	
	-- Only show buttons if player has Floor 3
	if extraFloors < FLOOR_ID then
		for _, buttonData in ipairs(buttons) do
			if buttonData.model.Parent then
				buttonData.model.Parent = nil
			end
		end
		return
	end
	
	-- Show only the next button to purchase
	for _, buttonData in ipairs(buttons) do
		local shouldShow = (buttonData.buttonId == pedestalGroupsUnlocked + 1)
		
		if shouldShow and not buttonData.model.Parent then
			buttonData.model.Parent = plot:YieldModel()
		elseif not shouldShow and buttonData.model.Parent then
			buttonData.model.Parent = nil
		end
	end
end

local function setupButton(plot: ClientPlot.Type, buttonId: number)
	local model = plot:YieldModel()
	local buttonName = "ThirdFloorPedestalButton" .. buttonId
	local buttonModel = model:FindFirstChild(buttonName)

	if not buttonModel or not buttonModel:IsA("Model") then
		return
	end

	-- If this isn't the local player's plot, destroy the button
	if not plot:IsLocal() then
		buttonModel:Destroy()
		return
	end

	local buttonBase = buttonModel:FindFirstChild("ButtonBase")
	if not buttonBase or not buttonBase:IsA("BasePart") then
		return
	end

	local billboardGui = buttonBase:FindFirstChild("BillboardGui")
	if not billboardGui or not billboardGui:IsA("BillboardGui") then
		return
	end

	local subtitle = billboardGui:FindFirstChild("Subtitle")
	if not subtitle or not subtitle:IsA("TextLabel") then
		return
	end

	-- Get the price for this pedestal group
	local pedestalGroups = GameSettings.PedestalGroups[FLOOR_ID]
	if not pedestalGroups or not pedestalGroups[buttonId] then
		return
	end

	local price = pedestalGroups[buttonId].Price

	-- Update the subtitle text with the price
	subtitle.Text = "$" .. Functions.NumberShorten(price)

	-- Check if button is already set up
	local setupAttrName = "_" .. buttonName .. "Setup"
	if buttonBase:GetAttribute(setupAttrName) then
		return
	end

	buttonBase:SetAttribute(setupAttrName, true)

	-- Store button data
	local buttonData: ButtonData = {
		plot = plot,
		buttonId = buttonId,
		button = buttonBase,
		model = buttonModel,
		subtitle = subtitle,
		price = price,
		pedestalGroupsConnection = nil,
		moneyConnection = nil,
	}
	
	if not activeButtons[plot] then
		activeButtons[plot] = {}
	end
	table.insert(activeButtons[plot], buttonData)

	-- Set up touch detection
	local touchingParts: { [BasePart]: boolean } = {}
	local lastActivationTime = 0
	local DEBOUNCE_TIME = 1
	local activeAttrName = "_" .. buttonName .. "Active"
	
	buttonBase.Touched:Connect(function(other: BasePart)
		local character = LocalPlayer and LocalPlayer.Character
		if not character or not other or not other:IsDescendantOf(character) then
			return
		end

		-- Don't allow parts from tools to trigger button
		local parent = other.Parent
		while parent do
			if parent:IsA("Tool") then
				return
			end
			parent = parent.Parent
		end

		if not touchingParts[other] then
			touchingParts[other] = true
		end
		
		if buttonBase:GetAttribute(activeAttrName) ~= true then
			-- Check debounce
			local currentTime = workspace:GetServerTimeNow()
			if currentTime - lastActivationTime < DEBOUNCE_TIME then
				return
			end
			lastActivationTime = currentTime
			
			-- Set active immediately to debounce before any yields
			buttonBase:SetAttribute(activeAttrName, true)

			-- Play button bounce animation
			playButtonBounce(buttonBase)

			-- Check if player can afford
			local playerMoney = plot:Save("Money") or 0
			if playerMoney < price then
				NotificationCmds.Message("You cannot afford to buy this!", {
                    Color = Color3.fromRGB(255, 0, 0),
                })
				return
			end

			-- Get pedestal info for confirmation message
			local pedestalGroups = GameSettings.PedestalGroups[FLOOR_ID]
			local pedestalGroup = pedestalGroups and pedestalGroups[buttonId]
			if not pedestalGroup then
				return
			end
			
			local pedestalCount = #pedestalGroup.Pedestals

			-- Prompt player for confirmation
			local confirmed = Message.new(string.format("Would you like to buy +%d more pedestals for $%s?", pedestalCount, Functions.NumberShorten(price)), true)

			if confirmed then
				-- Attempt to purchase the pedestal group
				local success, pedestalsOrError = plot:Invoke("PurchasePedestalGroup")
				if success then
					local pedestalList = pedestalsOrError
					NotificationCmds.Message("Successfully purchased " .. #pedestalList .. " more pedestals!", {
	                    Color = Color3.fromRGB(0, 255, 0),
	                })
				else
					NotificationCmds.Message(pedestalsOrError or "Failed to purchase pedestals!", {
	                    Color = Color3.fromRGB(255, 0, 0),
	                })
				end
			end
		end
	end)

	buttonBase.TouchEnded:Connect(function(other: BasePart)
		local character = LocalPlayer and LocalPlayer.Character
		if not character or not other or not other:IsDescendantOf(character) then
			return
		end

		-- Don't allow parts from tools to trigger button
		local parent = other.Parent
		while parent do
			if parent:IsA("Tool") then
				return
			end
			parent = parent.Parent
		end

		touchingParts[other] = nil
		-- If no more local parts are touching, reset active state
		local any = false
		for _ in pairs(touchingParts) do
			any = true
			break
		end
		if not any then
			buttonBase:SetAttribute(activeAttrName, false)
		end
	end)

	-- Listen for PedestalGroupsUnlocked updates to update visibility
	buttonData.pedestalGroupsConnection = plot:SaveUpdated("PedestalGroupsUnlocked"):Connect(function(_value: number)
		updateButtonVisibility(plot)
	end)
	
	-- Listen for ExtraFloors updates to update visibility
	buttonData.moneyConnection = plot:SaveUpdated("ExtraFloors"):Connect(function(_value: number)
		updateButtonVisibility(plot)
	end)

	-- Initial visibility update
	updateButtonVisibility(plot)
end

-- Listen for plot creation
ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
	for i = 1, TOTAL_PEDESTAL_BUTTONS do
		setupButton(plot, i)
	end
end)

-- Clean up when plot is destroyed
ClientPlot.Destroying:Connect(function(plot: ClientPlot.Type)
	if activeButtons[plot] then
		for _, buttonData in ipairs(activeButtons[plot]) do
			destroyButton(buttonData)
		end
		activeButtons[plot] = nil
	end
end)

