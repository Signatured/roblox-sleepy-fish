--!strict

--[[
	Client-side UI for the AbusePanel.
	Opens when the player types /abuse and provides a GUI for executing abuse commands.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Network = require(ReplicatedStorage.Library.Client.Network)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Debounce tracking for execute buttons
local lastExecuteTimes = {
	GlobalMessage = 0,
	GlobalForceSpawn = 0,
	GlobalForceGive = 0,
	GlobalForceRarity = 0,
	GlobalGiveSpins = 0,
}
local DEBOUNCE_TIME = 0.25

-- Create the main UI
local function CreateUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AbusePanelGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	
	-- Main frame (background)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 600)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar
	
	-- Title text
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -60, 1, 0)
	titleText.Position = UDim2.new(0, 15, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "Abuse Panel"
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 20
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 18
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BorderSizePixel = 0
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)
	
	-- Scrolling frame for content
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -70)
	scrollFrame.Position = UDim2.new(0, 10, 0, 60)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = mainFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 15)
	listLayout.Parent = scrollFrame
	
	screenGui.Parent = playerGui
	
	return screenGui, scrollFrame
end

-- Create a section for a command
local function CreateCommandSection(parent: ScrollingFrame, title: string, fields: {{Name: string, PlaceholderText: string, DefaultValue: string?, IsNumber: boolean?}}, onExecute: ({[string]: any}) -> ())
	local section = Instance.new("Frame")
	section.Name = title .. "Section"
	section.Size = UDim2.new(1, 0, 0, 0)
	section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	section.BorderSizePixel = 0
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Parent = parent
	
	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0, 8)
	sectionCorner.Parent = section
	
	local sectionLayout = Instance.new("UIListLayout")
	sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sectionLayout.Padding = UDim.new(0, 8)
	sectionLayout.Parent = section
	
	local sectionPadding = Instance.new("UIPadding")
	sectionPadding.PaddingTop = UDim.new(0, 12)
	sectionPadding.PaddingBottom = UDim.new(0, 12)
	sectionPadding.PaddingLeft = UDim.new(0, 12)
	sectionPadding.PaddingRight = UDim.new(0, 12)
	sectionPadding.Parent = section
	
	-- Section title
	local sectionTitle = Instance.new("TextLabel")
	sectionTitle.Name = "SectionTitle"
	sectionTitle.Size = UDim2.new(1, 0, 0, 25)
	sectionTitle.BackgroundTransparency = 1
	sectionTitle.Text = title
	sectionTitle.Font = Enum.Font.GothamBold
	sectionTitle.TextSize = 16
	sectionTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	sectionTitle.LayoutOrder = 0
	sectionTitle.Parent = section
	
	-- Create input fields
	local inputBoxes = {}
	for i, field in ipairs(fields) do
		local fieldContainer = Instance.new("Frame")
		fieldContainer.Name = field.Name .. "Container"
		fieldContainer.Size = UDim2.new(1, 0, 0, 55)
		fieldContainer.BackgroundTransparency = 1
		fieldContainer.LayoutOrder = i
		fieldContainer.Parent = section
		
		-- Field label
		local fieldLabel = Instance.new("TextLabel")
		fieldLabel.Name = "Label"
		fieldLabel.Size = UDim2.new(1, 0, 0, 18)
		fieldLabel.Position = UDim2.new(0, 0, 0, 0)
		fieldLabel.BackgroundTransparency = 1
		fieldLabel.Text = field.Name
		fieldLabel.Font = Enum.Font.Gotham
		fieldLabel.TextSize = 13
		fieldLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
		fieldLabel.Parent = fieldContainer
		
		-- Input box
		local inputBox = Instance.new("TextBox")
		inputBox.Name = field.Name .. "Input"
		inputBox.Size = UDim2.new(1, 0, 0, 32)
		inputBox.Position = UDim2.new(0, 0, 0, 23)
		inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		inputBox.BorderSizePixel = 0
		inputBox.PlaceholderText = field.PlaceholderText
		inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
		inputBox.Text = field.DefaultValue or ""
		inputBox.Font = Enum.Font.Gotham
		inputBox.TextSize = 14
		inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		inputBox.TextXAlignment = Enum.TextXAlignment.Left
		inputBox.ClearTextOnFocus = false
		inputBox.Parent = fieldContainer
		
		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = UDim.new(0, 6)
		inputCorner.Parent = inputBox
		
		local inputPadding = Instance.new("UIPadding")
		inputPadding.PaddingLeft = UDim.new(0, 10)
		inputPadding.PaddingRight = UDim.new(0, 10)
		inputPadding.Parent = inputBox
		
		inputBoxes[field.Name] = inputBox
	end
	
	-- Execute button
	local executeButton = Instance.new("TextButton")
	executeButton.Name = "ExecuteButton"
	executeButton.Size = UDim2.new(1, 0, 0, 40)
	executeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	executeButton.Text = "Execute"
	executeButton.Font = Enum.Font.GothamBold
	executeButton.TextSize = 15
	executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	executeButton.BorderSizePixel = 0
	executeButton.LayoutOrder = #fields + 1
	executeButton.Parent = section
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = executeButton
	
	-- Hover effect
	executeButton.MouseEnter:Connect(function()
		executeButton.BackgroundColor3 = Color3.fromRGB(120, 220, 120)
	end)
	
	executeButton.MouseLeave:Connect(function()
		executeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	end)
	
	-- Execute button click
	executeButton.MouseButton1Click:Connect(function()
		-- Check debounce
		local currentTime = tick()
		if currentTime - lastExecuteTimes[title] < DEBOUNCE_TIME then
			return
		end
		lastExecuteTimes[title] = currentTime
		
		-- Gather input values
		local values: {[string]: any} = {}
		for fieldName, inputBox in pairs(inputBoxes) do
			local text = inputBox.Text
			if text and text ~= "" then
				-- Find the field definition to check if it's a number
				for _, field in ipairs(fields) do
					if field.Name == fieldName then
						if field.IsNumber then
							local num = tonumber(text)
							if num then
								values[fieldName] = num
							else
								values[fieldName] = nil
							end
						else
							values[fieldName] = text
						end
						break
					end
				end
			else
				values[fieldName] = nil
			end
		end
		
		-- Execute the command
		onExecute(values)
		
		-- Visual feedback
		executeButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
		task.wait(0.1)
		executeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	end)
	
	return section
end

-- Create the UI
local screenGui, scrollFrame = CreateUI()

-- Create command sections

-- GlobalMessage
CreateCommandSection(scrollFrame, "GlobalMessage", {
	{Name = "Message", PlaceholderText = "Enter message to broadcast", IsNumber = false},
}, function(values)
	Network.Fire("AbusePanel_GlobalMessage", values.Message)
end)

-- GlobalForceSpawn
CreateCommandSection(scrollFrame, "GlobalForceSpawn", {
	{Name = "FishId", PlaceholderText = "Enter Fish ID", IsNumber = false},
	{Name = "Type", PlaceholderText = "Normal, Shiny, etc.", DefaultValue = "Normal", IsNumber = false},
	{Name = "Mutation", PlaceholderText = "Mutation ID (optional)", IsNumber = false},
	{Name = "Traits", PlaceholderText = "Trait1,Trait2,... (optional)", IsNumber = false},
}, function(values)
	Network.Fire("AbusePanel_GlobalForceSpawn", values.FishId, values.Type, values.Mutation, values.Traits)
end)

-- GlobalForceGive
CreateCommandSection(scrollFrame, "GlobalForceGive", {
	{Name = "FishId", PlaceholderText = "Enter Fish ID", IsNumber = false},
	{Name = "Type", PlaceholderText = "Normal, Shiny, etc.", DefaultValue = "Normal", IsNumber = false},
	{Name = "Mutation", PlaceholderText = "Mutation ID (optional)", IsNumber = false},
	{Name = "Traits", PlaceholderText = "Trait1,Trait2,... (optional)", IsNumber = false},
	{Name = "Level", PlaceholderText = "Level (default: 1)", DefaultValue = "1", IsNumber = true},
}, function(values)
	Network.Fire("AbusePanel_GlobalForceGive", values.FishId, values.Type, values.Mutation, values.Traits, values.Level)
end)

-- GlobalForceRarity
CreateCommandSection(scrollFrame, "GlobalForceRarity", {
	{Name = "RarityId", PlaceholderText = "Enter Rarity ID", IsNumber = false},
	{Name = "Type", PlaceholderText = "Normal, Shiny, etc. (optional)", IsNumber = false},
	{Name = "Mutation", PlaceholderText = "Mutation ID (optional)", IsNumber = false},
	{Name = "Traits", PlaceholderText = "Trait1,Trait2,... (optional)", IsNumber = false},
}, function(values)
	Network.Fire("AbusePanel_GlobalForceRarity", values.RarityId, values.Type, values.Mutation, values.Traits)
end)

-- GlobalGiveSpins
CreateCommandSection(scrollFrame, "GlobalGiveSpins", {
	{Name = "WheelId", PlaceholderText = "Enter Wheel ID", IsNumber = false},
	{Name = "Amount", PlaceholderText = "Number of spins", IsNumber = true},
	{Name = "SpinType", PlaceholderText = "Free or Paid (default: Free)", DefaultValue = "Free", IsNumber = false},
}, function(values)
	local amount = values.Amount or 1
	if typeof(amount) == "string" then
		amount = tonumber(amount) or 1
	end
	Network.Fire("AbusePanel_GlobalGiveSpins", values.WheelId, amount, values.SpinType)
end)

-- Listen for server event to open panel
Network.Fired("AbusePanel_Open", function()
	screenGui.Enabled = true
end)

-- Close panel on ESC key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and screenGui.Enabled then
		screenGui.Enabled = false
	end
end)

