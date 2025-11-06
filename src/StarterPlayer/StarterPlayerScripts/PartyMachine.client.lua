--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Functions = require(ReplicatedStorage.Library.Functions)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local Message = require(ReplicatedStorage.Library.Client.Message)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local PartyMachineCmds = require(ReplicatedStorage.Game.Library.Client.PartyMachineCmds)
local FFlags = require(ReplicatedStorage.Library.Client.FFlags)
local Network = require(ReplicatedStorage.Library.Client.Network)
local AdminAbuseEventCmds = require(ReplicatedStorage.Game.Library.Client.AdminAbuseEventCmds)

local _player = Players.LocalPlayer
local partyMachineGui = GUI.PartyMachine()
local frame = partyMachineGui:WaitForChild("Frame")
local mainFrame = frame:WaitForChild("MainFrame")
local content = mainFrame:WaitForChild("Content")
local scrolling = content:WaitForChild("ScrollingFrame")
local template = scrolling:WaitForChild("SellFish")
template.Visible = false

-- Progress bar
local progressBarFrame = content:WaitForChild("ProgressBar")
local progressFrame = progressBarFrame:WaitForChild("Progress")
local barFrame = progressFrame:WaitForChild("Bar")
local progressTextLabel = progressFrame:WaitForChild("TextLabel")

-- Footer controls
local submitAllButton = content:FindFirstChild("SellAll")
local inventoryValueLabel = content:FindFirstChild("InventoryValue")

-- Party machine billboard tracking
local partyBillboards: {BillboardGui} = {}
local partyEventStartTime = 0
local partyEventDuration = 300

-- Party GUI surface guis tracking
local partyGuis: {SurfaceGui} = {}

-- Update party machine billboard
local function updatePartyBillboard(billboard: BillboardGui)
	local pointsLabel = billboard:FindFirstChild("Points")
	if not pointsLabel or not pointsLabel:IsA("TextLabel") then
		return
	end
	
	-- Check if admin abuse party is forced on
	local isAdminAbuse = FFlags.Get(FFlags.Keys.AdminAbuseEvent_Party) == true
	local isPartyActive = AdminAbuseEventCmds.IsActive("Party")
	
	if isPartyActive then
		if isAdminAbuse then
			-- Admin abuse party active
			pointsLabel.Text = "Admin Abuse Party active now!"
		else
			-- Party machine started the event, show countdown
			local currentTime = workspace:GetServerTimeNow()
			local timeElapsed = currentTime - partyEventStartTime
			local timeRemaining = math.max(0, partyEventDuration - timeElapsed)
			
			local minutes = math.floor(timeRemaining / 60)
			local seconds = math.floor(timeRemaining % 60)
			pointsLabel.Text = string.format("Party ends in %d:%02d!", minutes, seconds)
		end
	else
		-- Party not active, show points needed
		local currentPoints = PartyMachineCmds.GetCurrentPoints()
		local goal = PartyMachineCmds.GetPointGoal()
		local pointsNeeded = math.max(0, goal - currentPoints)
		
		pointsLabel.Text = `Party in {Functions.Commas(pointsNeeded)} more points!`
	end
end

-- Update party GUI surface gui
local function updatePartyGui(surfaceGui: SurfaceGui)
	local frame = surfaceGui:FindFirstChild("Frame")
	if not frame or not frame:IsA("Frame") then
		return
	end
	
	-- Update event text
	local eventFrame = frame:FindFirstChild("Event")
	if eventFrame and eventFrame:IsA("Frame") then
		local textLabel = eventFrame:FindFirstChild("TextLabel")
		if textLabel and textLabel:IsA("TextLabel") then
			local isAdminAbuse = FFlags.Get(FFlags.Keys.AdminAbuseEvent_Party) == true
			local isPartyActive = AdminAbuseEventCmds.IsActive("Party")
			
			if isPartyActive then
				if isAdminAbuse then
					-- Admin abuse party active
					textLabel.Text = `<font color="#ffef0e">Party Event</font> is currently active!`
				else
					-- Party machine started the event, show countdown
					local currentTime = workspace:GetServerTimeNow()
					local timeElapsed = currentTime - partyEventStartTime
					local timeRemaining = math.max(0, partyEventDuration - timeElapsed)
					
					local minutes = math.floor(timeRemaining / 60)
					local seconds = math.floor(timeRemaining % 60)
					textLabel.Text = string.format(`<font color="#ffef0e">Party Event</font> ends in %d:%02d!`, minutes, seconds)
				end
			else
				-- Party not active
				textLabel.Text = `<font color="#ffef0e">Party Event</font> start's when goal is reached!`
			end
			textLabel.RichText = true
		end
	end
	
	-- Update progress bar
	local progressBarFrame = frame:FindFirstChild("ProgressBar")
	if progressBarFrame and progressBarFrame:IsA("Frame") then
		local progressFrame = progressBarFrame:FindFirstChild("Progress")
		if progressFrame and progressFrame:IsA("Frame") then
			local barFrame = progressFrame:FindFirstChild("Bar")
			local progressTextLabel = progressFrame:FindFirstChild("TextLabel")
			
			if barFrame and barFrame:IsA("Frame") then
				local currentPoints = PartyMachineCmds.GetCurrentPoints()
				local goalPoints = PartyMachineCmds.GetPointGoal()
				
				-- Calculate progress (0 to 1)
				local progress = 0
				if goalPoints > 0 then
					progress = math.clamp(currentPoints / goalPoints, 0, 1)
				end
				
				-- Update bar size
				barFrame.Size = UDim2.new(progress, 0, 1, 0)
				
				-- Update text label
				if progressTextLabel and progressTextLabel:IsA("TextLabel") then
					progressTextLabel.Text = `{Functions.Commas(currentPoints)}/{Functions.Commas(goalPoints)}`
				end
			end
		end
	end
end

local function updateProgressBar()
	local currentPoints = PartyMachineCmds.GetCurrentPoints()
	local goalPoints = PartyMachineCmds.GetPointGoal()
	
	-- Calculate progress (0 to 1)
	local progress = 0
	if goalPoints > 0 then
		progress = math.clamp(currentPoints / goalPoints, 0, 1)
	end
	
	-- Update bar size
	barFrame.Size = UDim2.new(progress, 0, 1, 0)
	
	-- Update text label
	progressTextLabel.Text = `{Functions.Commas(currentPoints)}/{Functions.Commas(goalPoints)}`
end

local function getPointsForFish(fishData: any): number
	local dir = Directory.Fish[fishData.FishId]
	if not dir then return 0 end
	
	-- Get rarity
	local rarityId = dir.Rarity and dir.Rarity._id
	if not rarityId then return 0 end
	
	-- Exclusive fish and SpecialItemFish can't be submitted
	if rarityId == "Exclusive" or dir.SpecialItemFish then return 0 end
	
	-- Get points from FFlags
	local flagKey = `PartyPoints_{rarityId}`
	if FFlags.Keys[flagKey] then
		local points = FFlags.Get(FFlags.Keys[flagKey])
		if typeof(points) == "number" then
			return points
		end
	end
	
	return 0
end

local function clearList()
	for _, child in ipairs(scrolling:GetChildren()) do
		if child:IsA("Frame") and child.Name == "PartyMachineItem" then
			child:Destroy()
		end
	end
end

local function createItem(fishData: any)
	local dir = Directory.Fish[fishData.FishId]
	if not dir then return end
	
	-- Skip SpecialItemFish
	if (dir.Rarity and dir.Rarity._id == "Exclusive") or dir.SpecialItemFish then return end

	local item = template:Clone()
	item.Name = "PartyMachineItem"
	item.Visible = true
	item.Parent = scrolling

	-- Image
	local fishContainer = item:FindFirstChild("FishContainer")
	local fishImage = fishContainer and fishContainer:FindFirstChild("FishImage")
	local imageLabel = fishImage and fishImage:FindFirstChild("ImageLabel")
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = dir.Icon or ""
	end

	-- Title
	local title = item:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = dir.DisplayName or dir._id or fishData.FishId
	end

	-- Level
	local levelLabel = item:FindFirstChild("Level")
	if levelLabel and levelLabel:IsA("TextLabel") then
		levelLabel.Text = string.format("Level %d", fishData.Level or 1)
	end

	-- Points (instead of Price)
	local priceLabel = item:FindFirstChild("Price")
	local pointAmount = getPointsForFish(fishData)
	if priceLabel and priceLabel:IsA("TextLabel") then
		priceLabel.Text = Functions.Commas(pointAmount) .. " Points"
	end

	-- Background gradient by rarity
	local background = item:FindFirstChild("Background")
	local uiGrad = background and background:FindFirstChild("UIGradient")
	local r = dir.Rarity
	if background and background:IsA("ImageLabel") and r then
		local rarityId = r._id
		if rarityId == "Mythical" then
			if uiGrad and uiGrad:IsA("UIGradient") then
				uiGrad.Enabled = false
			end
			local assets = ReplicatedStorage:FindFirstChild("Assets")
			local template = assets and assets:FindFirstChild("RainbowGradientWrapped")
			if template and template:IsA("UIGradient") then
				local grad = template:Clone()
				grad.Parent = background
				Functions.GradientScroll(grad, 2.5)
			end
		elseif rarityId == "God" then
			if uiGrad and uiGrad:IsA("UIGradient") then
				uiGrad.Enabled = false
			end
			local assets = ReplicatedStorage:FindFirstChild("Assets")
			local template = assets and assets:FindFirstChild("GodGradient")
			if template and template:IsA("UIGradient") then
				local grad = template:Clone()
				grad.Parent = background
				Functions.GradientScroll(grad, 2.5)
			end
		elseif rarityId == "Secret" then
			if uiGrad and uiGrad:IsA("UIGradient") then
				uiGrad.Enabled = false
			end
			local assets = ReplicatedStorage:FindFirstChild("Assets")
			local template = assets and assets:FindFirstChild("SecretGradient")
			if template and template:IsA("UIGradient") then
				local grad = template:Clone()
				grad.Parent = background
				Functions.GradientScroll(grad, 2.5)
			end
		else
			if uiGrad and uiGrad:IsA("UIGradient") then
				uiGrad.Enabled = true
				local color = (r :: any).Color or Color3.new(1, 1, 1)
				local h, s, v = color:ToHSV()
				local desat = Color3.fromHSV(h, math.max(0, s - 0.3), v)
				uiGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, color),
					ColorSequenceKeypoint.new(1, desat),
				})
			end
		end
	end

	-- Submit button (was Sell button)
	local sellButton = item:FindFirstChild("SellButton")
	if sellButton and sellButton:IsA("GuiButton") then
		ButtonFX(sellButton)
		sellButton.Activated:Connect(function()
			-- Check if event is already active
			if PartyMachineCmds.IsEventActive() then
				NotificationCmds.Message("The party is already in progress!", {
					Color = Color3.fromRGB(255, 0, 0)
				})
				return
			end
			
			-- Confirm if Mythical/God/Secret
			local rarityId = dir.Rarity and dir.Rarity._id
			if rarityId == "Mythical" or rarityId == "God" or rarityId == "Secret" then
				local points = getPointsForFish(fishData)
				local confirmText = string.format("You're giving a %s for %d Party Points, are you sure?", rarityId, points)
				local okConfirm = Message.new(confirmText, true)
				if not okConfirm then return end
			end
			
			-- Submit using PartyMachineCmds
			PartyMachineCmds.SubmitPoints({ fishData.UID })

			-- After submission, refresh list from save
			task.delay(0.05, function()
				local current = Save.Get()
				if current then
					render()
				end
			end)
		end)
	end
end

function render()
	clearList()
	local save = Save.Get()
	if not save then return end
	local inv = save.Inventory
	if type(inv) ~= "table" then return end
	
	-- Sort by point value (desc)
	table.sort(inv, function(a, b)
		return getPointsForFish(a) > getPointsForFish(b)
	end)
	
	for _, fishData in ipairs(inv) do
		createItem(fishData)
	end
	
	-- Update footer inventory value (total points)
	local total = 0
	for _, fishData in ipairs(inv) do
		local dir = Directory.Fish[fishData.FishId]
		local isExclusive = dir and dir.Rarity and dir.Rarity._id == "Exclusive"
		local isSpecialItem = dir and dir.SpecialItemFish
		if dir and not isExclusive and not isSpecialItem then
			total += getPointsForFish(fishData)
		end
	end
	if inventoryValueLabel and inventoryValueLabel:IsA("TextLabel") then
		inventoryValueLabel.Text = "Inventory Value: " .. Functions.Commas(total) .. " Points"
	end
	
	-- Update progress bar
	updateProgressBar()
end

-- Listen for party machine updates
-- These fire when the server updates points
Network.Fired("PartyMachine_PointsUpdated", function(_newPoints: number)
	updateProgressBar()
	
	-- Update all party guis
	for _, surfaceGui in ipairs(partyGuis) do
		if surfaceGui and surfaceGui.Parent then
			updatePartyGui(surfaceGui)
		end
	end
end)

Network.Fired("PartyMachine_EventStarted", function()
	updateProgressBar()
end)

Network.Fired("PartyMachine_EventEnded", function()
	updateProgressBar()
	
	-- Update all party guis when event ends
	for _, surfaceGui in ipairs(partyGuis) do
		if surfaceGui and surfaceGui.Parent then
			updatePartyGui(surfaceGui)
		end
	end
end)

-- Reactive: re-render when inventory changes
Save.Fired(function(key: string, _value: any)
	if key == "Inventory" then
		render()
	end
end)

-- Render on open via TabController
TabController.Opened:Connect(function(tabId: string)
	if tabId == "PartyMachine" then
		render()

		task.spawn(function()
			while true do
				if TabController.GetCurrentTab() ~= "PartyMachine" then break end
				Functions.UpdateCanvasSize(scrolling)
				task.wait(0.1)
			end
		end)
	end
end)

-- Wire SubmitAll behavior
if submitAllButton and submitAllButton:IsA("GuiButton") then
	ButtonFX(submitAllButton)
	submitAllButton.Activated:Connect(function()
		-- Check if event is already active
		if PartyMachineCmds.IsEventActive() then
			NotificationCmds.Message("The party is already in progress!", {
				Color = Color3.fromRGB(255, 0, 0)
			})
			return
		end
		
		local save = Save.Get()
		if not save or type(save.Inventory) ~= "table" then return end
		local uids = {}
		local hasMythical = false
		local hasGod = false
		local hasSecret = false
		local highestRarity = nil
		local highestPriority = -1
		
		for _, entry in ipairs(save.Inventory) do
			local dir = Directory.Fish[entry.FishId]
			if dir and not (dir.Rarity and dir.Rarity._id == "Exclusive") and not dir.SpecialItemFish then
				local rarityId = dir.Rarity and dir.Rarity._id
				local priority = dir.Rarity and dir.Rarity.Priority or 0
				
				if rarityId == "Mythical" then hasMythical = true end
				if rarityId == "God" then hasGod = true end
				if rarityId == "Secret" then hasSecret = true end
				
				if priority > highestPriority then
					highestPriority = priority
					highestRarity = rarityId
				end
				
				table.insert(uids, entry.UID)
			end
		end
		
		if #uids == 0 then return end
		
		-- Confirm if submitting any Mythical/God/Secret
		if hasSecret or hasMythical or hasGod then
			local which = highestRarity or "fish"
			local okConfirm = Message.new(string.format("Are you sure? You're submitting a %s fish!", which), true)
			if not okConfirm then return end
		end
		
		-- Submit using PartyMachineCmds
		PartyMachineCmds.SubmitPoints(uids)
		
		task.delay(0.05, function()
			render()
		end)
	end)
end

-- Setup TagHook for PartyMachineBillboard
Functions.TagHook("PartyMachineBillboard", function(inst: Instance)
	if not inst or not inst:IsA("BillboardGui") then
		return function() end
	end
	
	local billboard = inst :: BillboardGui
	table.insert(partyBillboards, billboard)
	updatePartyBillboard(billboard)
	
	-- Cleanup function
	return function()
		local index = table.find(partyBillboards, billboard)
		if index then
			table.remove(partyBillboards, index)
		end
	end
end)

-- Listen for party start to track event start time
Network.Fired("PartyMachine_EventStarted", function()
	partyEventStartTime = workspace:GetServerTimeNow()
	local durationValue = FFlags.Get(FFlags.Keys.PartyEventDuration)
	partyEventDuration = typeof(durationValue) == "number" and durationValue or 300
	
	-- Update all billboards and guis immediately
	for _, billboard in ipairs(partyBillboards) do
		if billboard and billboard.Parent then
			updatePartyBillboard(billboard)
		end
	end
	
	for _, surfaceGui in ipairs(partyGuis) do
		if surfaceGui and surfaceGui.Parent then
			updatePartyGui(surfaceGui)
		end
	end
end)

-- Setup TagHook for PartyGui
Functions.TagHook("PartyGui", function(inst: Instance)
	if not inst or not inst:IsA("SurfaceGui") then
		return function() end
	end
	
	local surfaceGui = inst :: SurfaceGui
	table.insert(partyGuis, surfaceGui)
	updatePartyGui(surfaceGui)
	
	-- Cleanup function
	return function()
		local index = table.find(partyGuis, surfaceGui)
		if index then
			table.remove(partyGuis, index)
		end
	end
end)

-- Update billboards and guis regularly
RunService.RenderStepped:Connect(function()
	for _, billboard in ipairs(partyBillboards) do
		if billboard and billboard.Parent then
			updatePartyBillboard(billboard)
		end
	end
	
	for _, surfaceGui in ipairs(partyGuis) do
		if surfaceGui and surfaceGui.Parent then
			updatePartyGui(surfaceGui)
		end
	end
end)

