--!strict

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local Marketplace = require(game.ReplicatedStorage.Library.Marketplace)
local ProductCmds = require(game.ReplicatedStorage.Library.Client.ProductCmds)
local Functions = require(game.ReplicatedStorage.Library.Functions)

-- Track active plots and their update loops
local activePlots: {[ClientPlot.Type]: thread} = {}

-- Configurable bounce tween settings (similar to Pedestals.client.lua)
local BUTTON_TWEEN_TOTAL_TIME = 0.3 -- seconds for full down-and-up cycle
local BUTTON_TWEEN_DEPTH = 0.2 -- studs to move down

local function playButtonBounce(buttonPart: BasePart)
    if not buttonPart or not buttonPart.Parent then return end
    if buttonPart:GetAttribute("_ButtonTweenActive") then return end
    buttonPart:SetAttribute("_ButtonTweenActive", true)

    local startPosition = buttonPart.Position
    local downPosition = startPosition - Vector3.new(0, BUTTON_TWEEN_DEPTH, 0)
    local halfDuration = BUTTON_TWEEN_TOTAL_TIME / 2
    local tweenInfo = TweenInfo.new(halfDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    task.spawn(function()
        -- Down
        local t1 = Functions.Tween(buttonPart, { Position = downPosition }, tweenInfo)
        if t1 and t1.Completed then t1.Completed:Wait() end
        -- Up
        if buttonPart.Parent then
            local t2 = Functions.Tween(buttonPart, { Position = startPosition }, tweenInfo)
            if t2 and t2.Completed then t2.Completed:Wait() end
        end
        buttonPart:SetAttribute("_ButtonTweenActive", false)
    end)
end

local function updateLockGui(plot: ClientPlot.Type)
	local model = plot:YieldModel()
	local lock = model:FindFirstChild("Lock")
	
	if not lock or not lock:IsA("BasePart") then
		return
	end
	
	local lockGui = lock:FindFirstChild("LockGui")
	
	if not lockGui or not lockGui:IsA("SurfaceGui") then
		return
	end
	
	-- Check if base is locked
	local lockTime = plot:Save("LockTime")
	local currentTime = workspace:GetServerTimeNow()
	local isLocked = typeof(lockTime) == "number" and lockTime > currentTime
	
	-- Update GUI visibility
	lockGui.Enabled = isLocked
	
	-- Update button color if it exists and this is the local plot
	if plot:IsLocal() then
		local lockButton = model:FindFirstChild("LockButton")
		if lockButton and lockButton:IsA("Model") then
			local button = lockButton:FindFirstChild("Button")
			if button and button:IsA("BasePart") then
				-- Green when locked (13, 193, 0), Red when unlocked (222, 0, 4)
				button.Color = isLocked and Color3.fromRGB(13, 193, 0) or Color3.fromRGB(222, 0, 4)
			end
		end
	end
end

local function setupLockButton(plot: ClientPlot.Type)
	local model = plot:YieldModel()
	local lockButton = model:FindFirstChild("LockButton")
	
	if not lockButton or not lockButton:IsA("Model") then
		return
	end
	
	-- If this isn't the local player's plot, destroy the button
	if not plot:IsLocal() then
		lockButton:Destroy()
		return
	end
	
	local button = lockButton:FindFirstChild("Button")
	
	if not button or not button:IsA("BasePart") then
		return
	end
	
	-- Check if button is already set up
	if button:GetAttribute("_LockButtonSetup") then
		return
	end
	
	button:SetAttribute("_LockButtonSetup", true)
	
	-- Set up touch detection (similar to Pedestals claim touch)
	local touchingParts: {[BasePart]: boolean} = {}
	button.Touched:Connect(function(other: BasePart)
		local character = LocalPlayer and LocalPlayer.Character
		if not character or not other or not other:IsDescendantOf(character) then return end
		
		-- Don't allow parts from tools to trigger lock button (check if descendant of Tool)
		local parent = other.Parent
		while parent do
			if parent:IsA("Tool") then return end
			parent = parent.Parent
		end
		
		if not touchingParts[other] then
			touchingParts[other] = true
		end
		if button:GetAttribute("_LockButtonActive") ~= true then
			-- Set active immediately to debounce before any yields
			button:SetAttribute("_LockButtonActive", true)
			
			-- Play button bounce animation
			playButtonBounce(button)
			
			-- Check if base is currently locked
			local lockTime = plot:Save("LockTime")
			local currentTime = workspace:GetServerTimeNow()
			local isLocked = typeof(lockTime) == "number" and lockTime > currentTime
			
			-- If base is locked, do nothing
			if isLocked then
				return
			end
			
			-- Prompt Lock Base product
			local productId = ProductCmds.GetProductId("Lock Base")
			if productId then
				Marketplace.Prompt(LocalPlayer, productId, true)
			end
		end
	end)
	
	button.TouchEnded:Connect(function(other: BasePart)
		local character = LocalPlayer and LocalPlayer.Character
		if not character or not other or not other:IsDescendantOf(character) then return end
		
		-- Don't allow parts from tools to trigger lock button (check if descendant of Tool)
		local parent = other.Parent
		while parent do
			if parent:IsA("Tool") then return end
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
			button:SetAttribute("_LockButtonActive", false)
		end
	end)
end

local function startPlotMonitoring(plot: ClientPlot.Type)
	-- Don't create duplicate monitoring threads
	if activePlots[plot] then
		return
	end
	
	-- Create monitoring thread
	local monitoringThread = task.spawn(function()
		while true do
			-- Check if plot still exists
			if not plot or not plot:YieldModel().Parent then
				break
			end
			
			updateLockGui(plot)
			task.wait(0.5)
		end
	end)
	
	activePlots[plot] = monitoringThread
	
	-- Initial update and button setup
	updateLockGui(plot)
	setupLockButton(plot)
end

local function stopPlotMonitoring(plot: ClientPlot.Type)
	local thread = activePlots[plot]
	if thread then
		task.cancel(thread)
		activePlots[plot] = nil
	end
end

-- Listen for plot creation
ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
	startPlotMonitoring(plot)
	
	-- Also listen for LockTime changes for immediate updates
	plot:SaveUpdated("LockTime"):Connect(function()
		updateLockGui(plot)
	end)
end)

-- Clean up when plots are destroyed
ClientPlot.Destroying:Connect(function(plot: ClientPlot.Type)
	stopPlotMonitoring(plot)
end)
