--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local TrickOrTreatHouseCmds = require(ReplicatedStorage.Game.Library.Client.TrickOrTreatHouseCmds)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Functions = require(ReplicatedStorage.Library.Functions)

local Assets = ReplicatedStorage:WaitForChild("Assets")

local TAG = "HalloweenHouse"
local DOOR_OPEN_ANGLE = 160
local DOOR_ANIMATION_TIME = 0.5
local DOOR_HOLD_TIME = 1

-- Create tween info for door animations
local tweenInfo = TweenInfo.new(
	DOOR_ANIMATION_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.InOut
)

-- Helper function to get house ID from a house model
local function getHouseId(houseModel: Instance): number?
	local id = houseModel:GetAttribute("Id")
	if typeof(id) == "number" then
		return id
	end
	return nil
end

-- Helper function to update prompt visibility based on cooldown
local function updatePromptVisibility(prompt: ProximityPrompt, houseId: number)
	local isOnCooldown = TrickOrTreatHouseCmds.IsOnCooldown(houseId)
	prompt.Enabled = not isOnCooldown
end

-- Helper function to update subtitle text based on cooldown
local function updateSubtitle(subtitle: TextLabel, houseId: number)
	local cooldownRemaining = TrickOrTreatHouseCmds.GetHouseCooldown(houseId)
	
	if cooldownRemaining <= 0 then
		subtitle.Text = "Claim Now!"
	else
		subtitle.Text = `Cooldown: {Functions.FormatTime(cooldownRemaining)}`
	end
end

-- Helper function to animate door opening and closing
local function animateDoor(door: Model, houseId: number)
	local primaryPart = door.PrimaryPart
	if not primaryPart then
		warn("[TrickOrTreatHouses] Door model has no PrimaryPart")
		return
	end
	
	-- Store original CFrame
	local originalCFrame = primaryPart.CFrame
	
	-- Calculate open CFrame (rotate 160 degrees around Y axis)
	local rotationCFrame = CFrame.Angles(0, math.rad(DOOR_OPEN_ANGLE), 0)
	local openCFrame = originalCFrame * rotationCFrame
	
	-- Open door
	local openTween = TweenService:Create(primaryPart, tweenInfo, {
		CFrame = openCFrame
	})
	
	openTween:Play()
	
	-- Wait for door to fully open
	openTween.Completed:Wait()
	
	-- Door is fully open, request trick or treat from server
	TrickOrTreatHouseCmds.RequestTrickOrTreat(houseId)
	
	-- Hold door open
	task.wait(DOOR_HOLD_TIME)
	
	-- Close door
	local closeTween = TweenService:Create(primaryPart, tweenInfo, {
		CFrame = originalCFrame
	})
	
	closeTween:Play()
end

-- Main TagHook setup
TagHook(TAG, function(instance: Instance)
	if not instance:IsA("Model") then
		return function() end
	end
	
	local houseModel = instance
	local houseId = getHouseId(houseModel)
	
	if not houseId or houseId < 1 or houseId > 5 then
		warn(`[TrickOrTreatHouses] House model {houseModel:GetFullName()} has invalid or missing Id attribute`)
		return function() end
	end
	
	-- Get the primary part
	local primaryPart = houseModel.PrimaryPart
	if not primaryPart then
		warn(`[TrickOrTreatHouses] House model {houseModel:GetFullName()} has no PrimaryPart`)
		return function() end
	end
	
	-- Find the ProximityAttachment
	local attachment = primaryPart:FindFirstChild("ProximityAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		warn(`[TrickOrTreatHouses] PrimaryPart of {houseModel:GetFullName()} has no ProximityAttachment`)
		return function() end
	end
	
	-- Find the BillboardGui and Subtitle
	local billboardGui = attachment:FindFirstChild("BillboardGui")
	local subtitle: TextLabel? = nil
	if billboardGui and billboardGui:IsA("BillboardGui") then
		local frame = billboardGui:FindFirstChild("Frame")
		if frame and frame:IsA("Frame") then
			local subtitleLabel = frame:FindFirstChild("Subtitle")
			if subtitleLabel and subtitleLabel:IsA("TextLabel") then
				subtitle = subtitleLabel
			end
		end
	end
	
	if not subtitle then
		warn(`[TrickOrTreatHouses] Could not find BillboardGui/Frame/Subtitle in {houseModel:GetFullName()}`)
	end
	
	-- Find the Door model
	local door = houseModel:FindFirstChild("Door")
	if not door or not door:IsA("Model") then
		warn(`[TrickOrTreatHouses] House model {houseModel:GetFullName()} has no Door model`)
		return function() end
	end
	
	-- Create ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TrickOrTreatPrompt"
	prompt.ActionText = "Trick or Treat!"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = attachment
	
	-- Set initial visibility and subtitle based on cooldown
	updatePromptVisibility(prompt, houseId)
	if subtitle then
		updateSubtitle(subtitle, houseId)
	end
	
	-- Connect to prompt triggered event
	local triggeredConnection = prompt.Triggered:Connect(function()
		-- Double check cooldown before animating
		if not TrickOrTreatHouseCmds.IsOnCooldown(houseId) then
			-- Disable prompt during animation
			prompt.Enabled = false
			
			-- Animate door
			animateDoor(door, houseId)
			
			-- Wait a bit before re-checking cooldown
			task.wait(0.5)
			updatePromptVisibility(prompt, houseId)
			if subtitle then
				updateSubtitle(subtitle, houseId)
			end
		end
	end)
	
	-- Listen for save updates to update prompt visibility and subtitle
	local saveUpdateConnection = Save.Fired(function(key: string, _value: any)
		if key == "TrickOrTreatHouses" then
			updatePromptVisibility(prompt, houseId)
			if subtitle then
				updateSubtitle(subtitle, houseId)
			end
		end
	end)
	
	-- Also check periodically in case of any desync and update subtitle every second
	local updateTask = task.spawn(function()
		while true do
			task.wait(1)
			if prompt and prompt.Parent then
				updatePromptVisibility(prompt, houseId)
				if subtitle then
					updateSubtitle(subtitle, houseId)
				end
			else
				break
			end
		end
	end)
	
	-- Cleanup function
	return function()
		pcall(function()
			if triggeredConnection then
				triggeredConnection:Disconnect()
			end
		end)
		pcall(function()
			if saveUpdateConnection then
				saveUpdateConnection:Disconnect()
			end
		end)
		pcall(function()
			if updateTask then
				task.cancel(updateTask)
			end
		end)
		pcall(function()
			if prompt then
				prompt:Destroy()
			end
		end)
	end
end)

-- TagHook for Trick or Treat fish VFX
local defaultScale = Vector3.new(5.565, 2.443, 2.823)

TagHook("SwimmingFish", function(instance: Instance)
	if not instance:IsA("Model") then
		return function() end
	end
	
	-- Check if this is a Trick or Treat fish
	if not instance:GetAttribute("TrickOrTreat") then
		return function() end
	end
	
	local fishModel = instance
	local vfxBox = fishModel:FindFirstChild("VFX")
	if not vfxBox or not vfxBox:IsA("BasePart") then
		return function() end
	end
	
	-- Get the particles template
	local particlesFolder = Assets:WaitForChild("Particles"):WaitForChild("Halloween"):WaitForChild("TrickOrTreat")
	if not particlesFolder then
		warn("[TrickOrTreatHouses] Could not find TrickOrTreat particles")
		return function() end
	end
	
	local function scaleParticlesRecursively(obj: Instance, scaleMultiplier: number)
		if obj:IsA("ParticleEmitter") and scaleMultiplier > 1.5 then
			scaleMultiplier = math.min(scaleMultiplier, 3)
			obj.Rate = obj.Rate * scaleMultiplier
		end
		for _, child in obj:GetChildren() do
			scaleParticlesRecursively(child, scaleMultiplier)
		end
	end
	
	-- Create attachment for VFX
	local attachment = Instance.new("Attachment")
	attachment.Name = "TrickOrTreatVFX"
	attachment.Parent = vfxBox
	
	-- Calculate scale multiplier
	local scale = vfxBox.Size
	local scaleMultiplier = scale.Magnitude / defaultScale.Magnitude
	
	-- Clone all particles from the template
	local clonedParticles: {ParticleEmitter} = {}
	local batsParticle: ParticleEmitter? = nil
	
	for _, obj in ipairs(particlesFolder:GetChildren()) do
		if obj:IsA("ParticleEmitter") then
			local clonedObj = obj:Clone()
			clonedObj.Parent = attachment
			scaleParticlesRecursively(clonedObj, scaleMultiplier)
			
			if clonedObj.Name == "Bats" then
				batsParticle = clonedObj
			else
				table.insert(clonedParticles, clonedObj)
			end
		end
	end
	
	-- Emit all particles once (except Bats)
	for _, particleEmitter in ipairs(clonedParticles) do
		Functions.Emit(particleEmitter)
	end
	
	-- Handle Bats particle separately - enable for 2 seconds
	if batsParticle then
		batsParticle.Enabled = true
		task.delay(2, function()
			if batsParticle then
				batsParticle.Enabled = false
			end
		end)
	end
	
	-- Cleanup function
	return function()
		pcall(function()
			if attachment then
				attachment:Destroy()
			end
		end)
	end
end)

