--!strict

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local Functions = require(game.ReplicatedStorage.Library.Functions)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local Message = require(game.ReplicatedStorage.Library.Client.Message)
local PlotTypes = require(game.ReplicatedStorage.Game.Library.Types.Plots)

-- Configurable bounce tween settings
local BUTTON_TWEEN_TOTAL_TIME = 0.3 -- seconds for full down-and-up cycle
local BUTTON_TWEEN_DEPTH = 0.2 -- studs to move down

-- Floor configurations
type FloorConfig = {
	ButtonName: string,
	FloorId: number,
	FloorName: string,
}

local FLOOR_CONFIGS: {FloorConfig} = {
	{
		ButtonName = "SecondFloorButton",
		FloorId = 1,
		FloorName = "Floor 2",
	},
	{
		ButtonName = "ThirdFloorButton",
		FloorId = 2,
		FloorName = "Floor 3",
	},
}

type ButtonData = {
	plot: ClientPlot.Type,
	button: BasePart,
	model: Model,
	extraFloorsConnection: any?,
	config: FloorConfig,
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
	-- Disconnect ExtraFloors listener
	if buttonData.extraFloorsConnection then
		pcall(function()
			buttonData.extraFloorsConnection:Disconnect()
		end)
		buttonData.extraFloorsConnection = nil
	end

	-- Destroy the model
	if buttonData.model and buttonData.model.Parent then
		buttonData.model:Destroy()
	end
end

local function removeButtonFromActive(plot: ClientPlot.Type, buttonData: ButtonData)
	if not activeButtons[plot] then
		return
	end
	
	for i, data in ipairs(activeButtons[plot]) do
		if data == buttonData then
			table.remove(activeButtons[plot], i)
			break
		end
	end
	
	if #activeButtons[plot] == 0 then
		activeButtons[plot] = nil
	end
end

local function updateButtonVisibility(plot: ClientPlot.Type, buttonData: ButtonData)
	local extraFloors = plot:Save("ExtraFloors") or 0
	
	-- Destroy button if player already has this floor
	if extraFloors >= buttonData.config.FloorId then
		destroyButton(buttonData)
		removeButtonFromActive(plot, buttonData)
		return
	end
	
	-- Hide button if player hasn't unlocked the prerequisite floor yet
	-- For example, Floor 3 (id=2) requires Floor 2 (ExtraFloors >= 1)
	local canBuy = extraFloors >= (buttonData.config.FloorId - 1)
	
	if canBuy and not buttonData.model.Parent then
		buttonData.model.Parent = plot:YieldModel()
	elseif not canBuy and buttonData.model.Parent then
		buttonData.model.Parent = nil
	end
end

local function setupButton(plot: ClientPlot.Type, config: FloorConfig)
	local model = plot:YieldModel()
	local floorButtonModel = model:FindFirstChild(config.ButtonName)

	if not floorButtonModel or not floorButtonModel:IsA("Model") then
		return
	end

	-- If this isn't the local player's plot, destroy the button
	if not plot:IsLocal() then
		floorButtonModel:Destroy()
		return
	end

	local button = floorButtonModel:FindFirstChild("Button")

	if not button or not button:IsA("BasePart") then
		return
	end

	-- Check if button is already set up
	local setupAttrName = "_" .. config.ButtonName .. "Setup"
	if button:GetAttribute(setupAttrName) then
		return
	end

	button:SetAttribute(setupAttrName, true)

	-- Store button data
	local buttonData: ButtonData = {
		plot = plot,
		button = button,
		model = floorButtonModel,
		extraFloorsConnection = nil,
		config = config,
	}
	
	if not activeButtons[plot] then
		activeButtons[plot] = {}
	end
	table.insert(activeButtons[plot], buttonData)
	
	-- Set initial visibility
	updateButtonVisibility(plot, buttonData)

	-- Set up touch detection
	local touchingParts: { [BasePart]: boolean } = {}
	local lastActivationTime = 0
	local DEBOUNCE_TIME = 1
	local activeAttrName = "_" .. config.ButtonName .. "Active"
	
	button.Touched:Connect(function(other: BasePart)
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
		if button:GetAttribute(activeAttrName) ~= true then
			-- Check debounce
			local currentTime = workspace:GetServerTimeNow()
			if currentTime - lastActivationTime < DEBOUNCE_TIME then
				return
			end
			lastActivationTime = currentTime
			
			-- Set active immediately to debounce before any yields
			button:SetAttribute(activeAttrName, true)

			-- Play button bounce animation
			playButtonBounce(button)

			-- Get the floor price
			local price = PlotTypes.FloorPrices[config.FloorId]
			if not price then
				return
			end

			-- Check if player can afford
			local playerMoney = plot:Save("Money") or 0
			if playerMoney < price then
				NotificationCmds.Message("You don't have enough money to buy " .. config.FloorName .. "!", {
                    Color = Color3.fromRGB(255, 0, 0),
                })
				return
			end

			-- Prompt player for confirmation
			local confirmed = Message.new(string.format("Would you like to buy %s for $%s?", config.FloorName, Functions.NumberShorten(price)), true)

			if confirmed then
				-- Purchase the floor
				local success, errorMsg = plot:Invoke("PurchaseExtraFloor", config.FloorId)
				if success then
					-- Button will be destroyed by the ExtraFloors listener
					NotificationCmds.Message("Successfully purchased " .. config.FloorName .. "!", {
                        Color = Color3.fromRGB(0, 255, 0),
                    })
				else
					NotificationCmds.Message(errorMsg or "Failed to purchase " .. config.FloorName .. "!", {
                        Color = Color3.fromRGB(255, 0, 0),
                    })
				end
			end
		end
	end)

	button.TouchEnded:Connect(function(other: BasePart)
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
			button:SetAttribute(activeAttrName, false)
		end
	end)

	-- Listen for ExtraFloors updates to show/hide button based on prerequisites
	buttonData.extraFloorsConnection = plot:SaveUpdated("ExtraFloors"):Connect(function(_value: number)
		updateButtonVisibility(plot, buttonData)
	end)
end

-- Listen for plot creation
ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
	for _, config in ipairs(FLOOR_CONFIGS) do
		setupButton(plot, config)
	end
end)

