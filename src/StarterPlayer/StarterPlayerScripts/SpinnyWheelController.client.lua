--!strict

-- This client script manages the UI and interaction logic for the spinny wheel.
-- It uses the Pad system to open the UI, validates spin availability, and handles the spin animation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Framework Modules
local Library = ReplicatedStorage:WaitForChild("Library")
local Pad = require(Library.Client.Pad)
local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(Library.Client.TabController)
local Network = require(Library.Client.Network)
local SpinnyWheelDirectory = require(ReplicatedStorage.Game.Library.Directory.SpinnyWheels)
local Functions = require(Library.Functions)
local Save = require(Library.Client.Save)
local ButtonFX = require(Library.Client.GUIFX.ButtonFX)
local Confetti = require(Library.Client.GUIFX.Confetti)
local Audio = require(Library.Audio)
local Signal = require(Library.Signal)

local TAG = "SpinnyWheel"
local spinDebounce = false
local currentWheelId: string? = nil

--// Configures the prize displays on the main ScreenGui.
local function setupMainGui(schema: any)
	local spinnyWheelGui = GUI.SpinnyWheel()
	if not spinnyWheelGui then return end
	
	local wheelCore = spinnyWheelGui.Frame.Wheel.Core
	for i, reward in ipairs(schema.Rewards) do
		local prizeFrame = wheelCore:FindFirstChild("Prize" .. i)
		if prizeFrame and prizeFrame:IsA("Frame") then
			local imageLabel: ImageLabel = prizeFrame.ImageLabel
			local percentLabel: TextLabel = prizeFrame.Percent
			local quantityLabel: TextLabel = prizeFrame.Quantity

			quantityLabel.Visible = false
			percentLabel.Position = UDim2.new(0.5, 0, 0.9, 0)

			imageLabel.Image = reward.Icon
			-- percentLabel.Text = reward.DisplayChance

			-- if reward.AltText then	
			-- 	quantityLabel.Text = reward.AltText
			-- else
			-- 	quantityLabel.Text = Functions.Commas(reward.Quantity)
			-- end

			if reward.AltText then	
				percentLabel.Text = reward.AltText
			else
				percentLabel.Text = "$" .. Functions.Commas(reward.Quantity)
			end
		end
	end
end
--// Updates the spin button text to show available spins for the current wheel.
local function updateSpinButtonText()
	if not currentWheelId then return end
	
	local spinnyWheelGui = GUI.SpinnyWheel()
	if not spinnyWheelGui then return end
	
	local spinButton = spinnyWheelGui.Frame:FindFirstChild("Spin")
	if not spinButton or not spinButton:IsA("GuiButton") then return end
	
	local textLabel = spinButton:FindFirstChild("TextLabel")
	if not textLabel or not textLabel:IsA("TextLabel") then return end
	
	local saveData = Save.Get()
	local spinsForWheel = saveData and saveData.WheelSpins and saveData.WheelSpins[currentWheelId] or 0
	textLabel.Text = `Spin ({spinsForWheel})`
end

--// Opens the spinny wheel UI for a specific wheel ID.
local function openSpinnyWheel(wheelId: string)
	local schema = SpinnyWheelDirectory[wheelId]
	if not schema then
		warn(`[SpinnyWheel] Could not find schema for wheelId: '{wheelId}'`)
		return
	end

	currentWheelId = wheelId
	setupMainGui(schema)
	updateSpinButtonText()
	TabController.OpenTab("SpinnyWheel")
end

--// Configures the prize displays on the physical wheel's SurfaceGui.
local function setupPhysicalWheel(physicalWheelPart: Part, schema: any)
	local surfaceGui = physicalWheelPart:FindFirstChildOfClass("SurfaceGui")
	if not surfaceGui then return end

	local wheelGui = surfaceGui:FindFirstChild("Wheel")
	if not wheelGui then return end

	local wheelCore = wheelGui:FindFirstChild("Core")
	if not wheelCore then return end

	for i, reward in ipairs(schema.Rewards) do
		local prizeFrame = wheelCore:FindFirstChild("Prize" .. i)::Frame
		if prizeFrame and prizeFrame:IsA("Frame") then
			local imageLabel: ImageLabel = prizeFrame:FindFirstChild("ImageLabel")::ImageLabel
			local percentLabel: TextLabel = prizeFrame:FindFirstChild("Percent")::TextLabel
			local quantityLabel: TextLabel = prizeFrame:FindFirstChild("Quantity")::TextLabel

			quantityLabel.Visible = false
			percentLabel.Position = UDim2.new(0.5, 0, 0.9, 0)

			imageLabel.Image = reward.Icon
			-- percentLabel.Text = reward.DisplayChance

			-- if reward.AltText then	
			-- 	quantityLabel.Text = reward.AltText
			-- else
			-- 	quantityLabel.Text = Functions.Commas(reward.Quantity)
			-- end

			if reward.AltText then	
				percentLabel.Text = reward.AltText
			else
				percentLabel.Text = "$" .. Functions.Commas(reward.Quantity)
			end
		end
	end
end


--// Plays the spin animation, pointing the arrow at the winning prize.
local function playSpinAnimation(wheelId: string, winningIndex: number)
	-- Only play the animation for the currently active wheel
	if wheelId ~= currentWheelId then return end
	
	spinDebounce = true
	
	local schema = SpinnyWheelDirectory[wheelId]
	if not schema then
		spinDebounce = false
		return
	end
	
	local spinnyWheelGui = GUI.SpinnyWheel()
	if not spinnyWheelGui then
		spinDebounce = false
		return
	end
	
	local wheelCore = spinnyWheelGui.Frame.Wheel.Core
	local prizeCount = #schema.Rewards
	local anglePerPrize = 360 / prizeCount
	
	-- Get the current rotation to use as a base for the new spin
	local currentRotation = wheelCore.Rotation
	
	-- Calculate the final rotation with a random offset within the prize slice
	local targetSliceCenter = -(winningIndex - 1) * anglePerPrize
	local randomOffset = (math.random() - 0.5) * (anglePerPrize * 0.8) -- Land within 80% of the slice
	local finalTarget = targetSliceCenter + randomOffset
	
	local finalRotation = currentRotation + (360 * 8) + (finalTarget - (currentRotation % 360))
	
	local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tween = TweenService:Create(wheelCore, tweenInfo, {Rotation = finalRotation})
	
	Audio.Play("rbxassetid://137080714801874", script)
	
	-- Play the result sound 0.5 seconds before the wheel stops.
	task.delay(4.7, function()
		-- Animate the winning prize
		local prizeFrame = wheelCore:FindFirstChild("Prize" .. winningIndex)
		if prizeFrame then
			local uiScale = prizeFrame:FindFirstChildOfClass("UIScale")
			if uiScale then
				local tween1 = Functions.Tween(uiScale, { Scale = 1.2 }, { "Quad", "Out", 0.2 }::{any})
				tween1.Completed:Connect(function()
					Functions.Tween(uiScale, { Scale = 1 }, { "Bounce", "Out", 0.5 }::{any})
				end)
			end
		end

		if winningIndex == 1 then
			-- Best prize
			Audio.Play("rbxassetid://127060120960810", script)
			Confetti()
		elseif winningIndex <= 3 then
			-- 2nd or 3rd best prize
			Audio.Play("rbxassetid://112721888429177", script)
		else
			-- Bottom 3 prizes
			Audio.Play("rbxassetid://98804626466967", script)
		end
	end)
	
	-- While the wheel is spinning, counter-rotate the prize frames to keep them upright.
	local counterRotateConnection: RBXScriptConnection
	counterRotateConnection = RunService.RenderStepped:Connect(function()
		for i = 1, prizeCount do
			local prizeFrame = wheelCore:FindFirstChild("Prize" .. i)
			if prizeFrame then
				prizeFrame.Rotation = -wheelCore.Rotation
			end
		end
	end)
	
	tween:Play()
	tween.Completed:Wait()
	
	counterRotateConnection:Disconnect()
	
	-- Tell the server the animation is done so it can grant the reward in the background.
	Network.Fire("SpinAnimationComplete")
	
	task.wait(2) -- Pause on the prize
	
	-- Update the spin button text to reflect the new spin count
	updateSpinButtonText()
	
	spinDebounce = false
end

--// Sets up a new spinny wheel instance when it's tagged.
Functions.TagHook(TAG, function(wheelModel: any)
	assert(wheelModel:IsA("Model"), "Tagged instance for SpinnyWheel must be a Model.")

	local wheelId = wheelModel:GetAttribute("Id")
	if not wheelId then
		error(`[SpinnyWheel] Model '{wheelModel:GetFullName()}' is tagged 'SpinnyWheel' but is missing string attribute 'Id'.`)
	end
	
	local schema = SpinnyWheelDirectory[wheelId]
	if not schema then
		error(`[SpinnyWheel] Could not find schema for wheelId: '{wheelId}'`)
	end
	
	local physicalSpinConnection: RBXScriptConnection

	-- Setup the physical wheel model in the workspace
	local physicalWheelPart = wheelModel:FindFirstChild("Wheel")
	if physicalWheelPart and physicalWheelPart:IsA("Part") then
		setupPhysicalWheel(physicalWheelPart, schema)
		
		local surfaceGui = physicalWheelPart:FindFirstChildOfClass("SurfaceGui")
		local wheelGui = surfaceGui and surfaceGui:FindFirstChild("Wheel")
		local wheelCore = wheelGui and wheelGui:FindFirstChild("Core")

		if wheelCore then
			-- 1 rotation every 30 seconds = 360 degrees / 30 seconds = 12 degrees per second.
			local rotationSpeed = 12
			
			physicalSpinConnection = RunService.RenderStepped:Connect(function(deltaTime)
				if wheelCore and wheelCore.Parent then
					wheelCore.Rotation = wheelCore.Rotation + (rotationSpeed * deltaTime)
					-- Also counter-rotate the prizes to keep them upright
					for i = 1, 6 do
						local prizeFrame = wheelCore:FindFirstChild("Prize" .. i)
						if prizeFrame then
							prizeFrame.Rotation = -wheelCore.Rotation
						end
					end
				end
			end)
		end
	end
	
	local padModel = wheelModel:FindFirstChild("Pad")
	if not padModel or not padModel:IsA("Model") then
		error(`[SpinnyWheel] Could not find a valid 'Pad' model inside '{wheelModel:GetFullName()}'.`)
	end
	
	local pad = Pad.new(padModel)
	
	local enterConn = pad:AddEnterListener(function(player)
		if player == Players.LocalPlayer then
			currentWheelId = wheelId
			setupMainGui(schema)
			updateSpinButtonText()
			TabController.OpenTab("SpinnyWheel")
		end
	end)
	
	local leaveConn = pad:AddLeaveListener(function(player)
		if player == Players.LocalPlayer then
			-- Close the tab if it's the active one
			if TabController.GetCurrentTab() == "SpinnyWheel" then
				TabController.CloseTab()
			end
			currentWheelId = nil
		end
	end)
	
	-- Return the cleanup function
	return function()
		enterConn.Disconnect()
		leaveConn.Disconnect()
		pad:Destroy()
		if physicalSpinConnection then
			physicalSpinConnection:Disconnect()
		end
		print(`[SpinnyWheel] Cleaned up wheel: {wheelModel.Name}`)
	end
end)


--// This only needs to be connected once.
local spinnyWheelGui = GUI.SpinnyWheel()
if spinnyWheelGui then
	local spinButton = spinnyWheelGui.Frame:FindFirstChild("Spin")
	if spinButton and spinButton:IsA("GuiButton") then
		ButtonFX(spinButton) -- Apply ButtonFX
		
		spinButton.Activated:Connect(function()
			if spinDebounce or not currentWheelId then return end
			
			-- Client-side check to see if player has spins available.
			local schema = SpinnyWheelDirectory[currentWheelId]
			local saveData = Save.Get()
			local spinsForWheel = saveData and saveData.WheelSpins and saveData.WheelSpins[currentWheelId] or 0
			if schema and saveData and spinsForWheel > 0 then
				Network.Fire("SpinWheel", currentWheelId)
			else
				print("[SpinnyWheel] No spins available for this wheel.")
			end
		end)
	end
end

-- Listen for save data changes to update the spin button text
Save.Fired(function(key: string, value: any)
	if key == "WheelSpins" then
		updateSpinButtonText()
	end
end)

-- Listen for the result from the server
Network.Fired("SpinWheelResult", playSpinAnimation)

-- Listen for a signal to open the wheel UI.
Signal.Fired("OpenSpinnyWheel"):Connect(openSpinnyWheel)