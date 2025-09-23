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
local Marketplace = require(Library.Marketplace)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)

local TAG = "SpinnyWheel"
local spinDebounce = false
local currentWheelId: string? = nil
local freeSpinUpdateConn: RBXScriptConnection? = nil
local purchaseUIHooked = false

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
			local title1 = prizeFrame:FindFirstChild("Title1")
			local title2 = prizeFrame:FindFirstChild("Title2")
			local title3 = prizeFrame:FindFirstChild("Title3")
			percentLabel.Position = UDim2.new(0.5, 0, 0.9, 0)

			imageLabel.Image = reward.Icon
			-- percentLabel.Text = reward.DisplayChance

			if title1 and title1:IsA("TextLabel") then
				title1.Text = reward.Title1 or ""
			end
			if title2 and title2:IsA("TextLabel") then
				title2.Text = reward.Title2 or ""
			end
			if title3 and title3:IsA("TextLabel") then
				title3.Text = reward.Title3 or ""
			end

			percentLabel.Text = reward.DisplayChance
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
    local w = saveData and saveData.Wheels and saveData.Wheels[currentWheelId]
    local total = (w and ((w.Free or 0) + (w.Paid or 0))) or 0
    textLabel.Text = `Spin ({total})`
end

--// Updates the FreeSpinIn label text once
local function updateFreeSpinLabel()
    if not currentWheelId then return end
    local spinnyWheelGui = GUI.SpinnyWheel()
    if not spinnyWheelGui then return end
    local frame = spinnyWheelGui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return end
    local spinButton = frame:FindFirstChild("Spin")
    if not spinButton or not spinButton:IsA("GuiButton") then return end
    local freeLabel = spinButton:FindFirstChild("FreeSpinIn")
    if not freeLabel or not freeLabel:IsA("TextLabel") then return end

    local saveData = Save.Get()
    local w = saveData and saveData.Wheels and saveData.Wheels[currentWheelId]
    if not w then
        freeLabel.Text = ""
        return
    end

    if (w.Free or 0) > 0 then
        freeLabel.Text = "Free spin ready!"
        return
    end

    local nextAt = w.FreeNextAt
    if typeof(nextAt) == "number" then
        local nowT = workspace:GetServerTimeNow()
        local remaining = math.max(0, nextAt - nowT)
        if remaining > 0 then
            freeLabel.Text = "Free spin in: " .. Functions.FormatTime(remaining)
        else
            freeLabel.Text = "Free spin ready!"
        end
    else
        freeLabel.Text = ""
    end
end

--// Starts 1s ticker to update FreeSpinIn while UI is open
local function startFreeSpinTicker()
    if freeSpinUpdateConn then freeSpinUpdateConn:Disconnect() end
    local accum = 1
    freeSpinUpdateConn = RunService.Heartbeat:Connect(function(dt)
        accum -= dt
        if accum <= 0 then
            accum = 1
            updateFreeSpinLabel()
        end
    end)
    -- Immediate update
    updateFreeSpinLabel()
end

--// Daily deal availability (once per day; resets after midnight EST)
local EST_OFFSET = -5 * 3600
local function getESTDayKey(): number
    local now = workspace:GetServerTimeNow()
    local est = now + EST_OFFSET
    return math.floor(est / 86400)
end

local function isDailyDealAvailable(): boolean
    local saveData = Save.Get()
    if not saveData then return false end
    local lastKey = saveData.WheelDailyDealDayKey
    local todayKey = getESTDayKey()
    return lastKey ~= todayKey
end

--// Update Buy1/Buy3 UI (prices, discount badge, positions)
local function updatePurchaseUI()
    local spinnyWheelGui = GUI.SpinnyWheel()
    if not spinnyWheelGui then return end
    local frame = spinnyWheelGui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return end

    local buy1 = frame:FindFirstChild("Buy1Spin")
    local buy3 = frame:FindFirstChild("Buy3Spins")
    if not (buy1 and buy1:IsA("GuiButton") and buy3 and buy3:IsA("GuiButton")) then return end

    -- Hook ButtonFX once
    if not purchaseUIHooked then
        ButtonFX(buy1 :: GuiButton)
        ButtonFX(buy3 :: GuiButton)
        purchaseUIHooked = true
    end

    -- Resolve labels under Buy1
    local dailyDiscount = buy1:FindFirstChild("DailyDiscount")
    local luck = buy1:FindFirstChild("Luck")
    local cost1 = buy1:FindFirstChild("Cost")
    if dailyDiscount and dailyDiscount:IsA("TextLabel") and luck and luck:IsA("TextLabel") and cost1 and cost1:IsA("TextLabel") then
        local discount = isDailyDealAvailable()
        dailyDiscount.Visible = discount
        if discount then
            luck.Position = UDim2.new(0.49, 0, -0.569, 0)
        else
            luck.Position = UDim2.new(0.49, 0, -0.233, 0)
        end

        -- Price
        local discountedProduct = Products["Buy 1 Spin Discounted"]
        local normalProduct = Products["Buy 1 Spin"]
        local selected = discount and discountedProduct or normalProduct
        if selected and typeof(selected.ProductId) == "number" then
            cost1.Text = " ???"
            task.spawn(function()
                local price = Functions.GetRobuxPrice(selected.ProductId, true)
                if price and cost1 and cost1:IsA("TextLabel") then
                    cost1.Text = ` {price}`
                end
            end)
        end
    end

    -- Price for Buy3Spins
    local cost3 = buy3:FindFirstChild("Cost")
    local product3 = Products["Buy 3 Spins"]
    if cost3 and cost3:IsA("TextLabel") and product3 and typeof(product3.ProductId) == "number" then
        cost3.Text = " ???"
        task.spawn(function()
            local price = Functions.GetRobuxPrice(product3.ProductId, true)
            if price and cost3 and cost3:IsA("TextLabel") then
                cost3.Text = ` {price}`
            end
        end)
    end
end

local function stopFreeSpinTicker()
    if freeSpinUpdateConn then
        freeSpinUpdateConn:Disconnect()
        freeSpinUpdateConn = nil
    end
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
    updatePurchaseUI()
    startFreeSpinTicker()
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
			local title1 = prizeFrame:FindFirstChild("Title1")
			local title2 = prizeFrame:FindFirstChild("Title2")
			local title3 = prizeFrame:FindFirstChild("Title3")
			percentLabel.Position = UDim2.new(0.5, 0, 0.9, 0)

			imageLabel.Image = reward.Icon
			-- percentLabel.Text = reward.DisplayChance

			if title1 and title1:IsA("TextLabel") then
				title1.Text = reward.Title1 or ""
			end
			if title2 and title2:IsA("TextLabel") then
				title2.Text = reward.Title2 or ""
			end
			if title3 and title3:IsA("TextLabel") then
				title3.Text = reward.Title3 or ""
			end

			percentLabel.Text = reward.DisplayChance
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
	local physicalWheelPart = wheelModel:FindFirstChild("Inside")
	if physicalWheelPart then
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
            updatePurchaseUI()
            startFreeSpinTicker()
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
            stopFreeSpinTicker()
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
		
        -- Hook buy buttons once
        local frame = spinnyWheelGui:FindFirstChild("Frame")
        if frame and frame:IsA("Frame") then
            local buy1 = frame:FindFirstChild("Buy1Spin")
            local buy3 = frame:FindFirstChild("Buy3Spins")
            if buy1 and buy1:IsA("GuiButton") and buy3 and buy3:IsA("GuiButton") then
                ButtonFX(buy1)
                ButtonFX(buy3)
                if not purchaseUIHooked then
                    purchaseUIHooked = true
                    buy1.Activated:Connect(function()
                        local discount = isDailyDealAvailable()
                        local selected = Products[discount and "Buy 1 Spin Discounted" or "Buy 1 Spin"]
                        if selected and typeof(selected.ProductId) == "number" then
                            Marketplace.Prompt(Players.LocalPlayer, selected.ProductId, true)
                        end
                    end)
                    buy3.Activated:Connect(function()
                        local p3 = Products["Buy 3 Spins"]
                        if p3 and typeof(p3.ProductId) == "number" then
                            Marketplace.Prompt(Players.LocalPlayer, p3.ProductId, true)
                        end
                    end)
                end
            end
        end

		spinButton.Activated:Connect(function()
			if spinDebounce or not currentWheelId then return end
			
			-- Client-side check to see if player has spins available.
            local schema = SpinnyWheelDirectory[currentWheelId]
            local saveData = Save.Get()
            local w = saveData and saveData.Wheels and saveData.Wheels[currentWheelId]
            local total = (w and ((w.Free or 0) + (w.Paid or 0))) or 0
            if schema and saveData and total > 0 then
				Network.Fire("SpinWheel", currentWheelId)
			else
				print("[SpinnyWheel] No spins available for this wheel.")
			end
		end)
	end
end

-- Listen for save data changes to update the spin button text
Save.Fired(function(key: string, value: any)
    if key == "Wheels" then
        updateSpinButtonText()
        updateFreeSpinLabel()
		updatePurchaseUI()			
    end
end)

-- Listen for the result from the server
Network.Fired("SpinWheelResult", playSpinAnimation)

-- Listen for a signal to open the wheel UI.
Signal.Fired("OpenSpinnyWheel"):Connect(openSpinnyWheel)

-- Stop ticker when SpinnyWheel tab closes
TabController.Closed:Connect(function(tabId: string)
    if tabId == "SpinnyWheel" then
        stopFreeSpinTicker()
    end
end)