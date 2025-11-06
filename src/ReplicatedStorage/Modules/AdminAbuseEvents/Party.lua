--!strict

--[[
	Client-side logic for Party event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local AdminAbuseEventCmds = require(ReplicatedStorage.Game.Library.Client.AdminAbuseEventCmds)
local Functions = require(ReplicatedStorage.Library.Functions)
local Audio = require(ReplicatedStorage.Library.Audio)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local Assets = ReplicatedStorage.Assets

local module = {}

-- Shared state for this event
local cannons: {[number]: Model} = {}
local _isActive = false

-- Helper function to get fish type display
local function getFishType(fishType: string): (string?, Color3?)
	if fishType == "Shiny" then
		return "Shiny", Color3.fromRGB(255, 255, 255)
	elseif fishType == "Gold" then
		return "Gold", Color3.fromRGB(255, 215, 0)
	elseif fishType == "Rainbow" then
		return "Rainbow"
	end
	return nil
end

-- Setup billboard for temporary fish with Party trait
local function setupTempBillboard(model: Model, fishId: string, fishType: string, mutation: string?): BillboardGui?
	local primaryPart = model.PrimaryPart
	if not primaryPart then return nil end
	
	local fishDir = Directory.Fish[fishId]
	if not fishDir then return nil end
	
	local billboardOffset = fishDir.BillboardOffset
	
	local billboard = Assets.FishPedestalGui:Clone()::BillboardGui
	billboard.StudsOffsetWorldSpace = Vector3.new(0, billboardOffset, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = primaryPart
	
	-- Update the billboard with visual data
	local frame = billboard:WaitForChild("Frame")::Frame
	local displayName = frame:WaitForChild("DisplayName")::TextLabel
	local rarity = frame:WaitForChild("Rarity")::TextLabel
	local level = frame:WaitForChild("Level")::TextLabel
	local fishTypeLabel = frame:WaitForChild("FishType")::TextLabel
	local mutationLabel = frame:WaitForChild("Mutation")::TextLabel
	local traitsFrame = frame:WaitForChild("Traits")::Frame
	
	-- Hide money and level info during animation
	local moneyPerSecond = frame:FindFirstChild("MoneyPerSecond")
	if moneyPerSecond then moneyPerSecond:Destroy() end
	local money = frame:FindFirstChild("Money")
	if money then money:Destroy() end
	local offlineEarnings = frame:FindFirstChild("OfflineEarnings")
	if offlineEarnings then offlineEarnings:Destroy() end
	level.Visible = false
	
	displayName.Text = fishDir.DisplayName
	rarity.Text = fishDir.Rarity.DisplayName
	rarity.TextColor3 = fishDir.Rarity.Color
	
	-- Show fish type
	local typeName, typeColor = getFishType(fishType)
	if typeName then
		fishTypeLabel.Text = typeName
		fishTypeLabel.TextColor3 = typeColor or Color3.fromRGB(255, 255, 255)
		fishTypeLabel.Visible = true
	else
		fishTypeLabel.Visible = false
	end
	
	-- Show mutation if present
	if mutation then
		local mutationDir = Directory.Mutations[mutation]
		if mutationDir then
			mutationLabel.Text = mutationDir.DisplayName
			mutationLabel.TextColor3 = mutationDir.Color
			mutationLabel.Visible = true
		else
			mutationLabel.Visible = false
		end
	else
		mutationLabel.Visible = false
	end
	
	-- Show Party trait
	local template = traitsFrame:FindFirstChild("Template")
	if template and template:IsA("ImageLabel") then
		-- Clear existing trait icons (except template)
		for _, child in ipairs(traitsFrame:GetChildren()) do
			if child:IsA("ImageLabel") and child ~= template then
				child:Destroy()
			end
		end
		
		local partyTrait = Directory.Traits["Party"]
		if partyTrait then
			traitsFrame.Visible = true
			
			local icon = template:Clone()
			icon.Name = "Party"
			icon.Image = partyTrait.Icon
			icon.Visible = true
			icon.LayoutOrder = 1
			icon.Parent = traitsFrame
		else
			traitsFrame.Visible = false
		end
	end
	
	return billboard
end

-- Setup a party cannon when it's found
local function setupCannon(cannonModel: Model)
	local cannonId = cannonModel:GetAttribute("Id")
	if typeof(cannonId) ~= "number" then
		warn("[Party Client] PartyCannon model missing 'Id' number attribute")
		return
	end
	
	cannons[cannonId] = cannonModel
	print(`[Party Client] Registered cannon {cannonId}`)
end

-- Animate the cannon firing
local function animateCannon(cannonModel: Model, aimDuration: number, cannonAnimDuration: number, targetPosition: Vector3): Attachment?
	-- Find the ShootPart
	local shootPart = cannonModel:FindFirstChild("ShootPart")
	if not shootPart or not shootPart:IsA("Model") then
		warn("[Party Client] ShootPart not found in cannon")
		return nil
	end
	
	local primaryPart = shootPart.PrimaryPart
	if not primaryPart then
		warn("[Party Client] ShootPart has no PrimaryPart")
		return nil
	end
	
	-- Get the Muzzle attachment
	local muzzleAttachment = primaryPart:FindFirstChild("Muzzle")
	if not muzzleAttachment or not muzzleAttachment:IsA("Attachment") then
		warn("[Party Client] Muzzle attachment not found")
		return nil
	end
	
	-- Step 1: Aim the ShootPart at the target
	local currentCFrame = shootPart:GetPivot()
	local direction = (targetPosition - currentCFrame.Position).Unit
	local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + direction)
	
	local aimTween = Functions.Tween(shootPart, {
		CFrame = targetCFrame
	}, {"Sine", "Out", aimDuration}::{any})
	
	-- Step 2: After aiming, shrink to 0.6, then grow back to 1
	aimTween.Completed:Connect(function()
		local originalScale = cannonModel:GetScale()
		
		-- Half of cannon animation duration for each part (shrink and grow)
		local halfDuration = cannonAnimDuration / 2
		
		-- Shrink
		local shrinkTween = Functions.Tween(cannonModel, {
			Scale = 0.6
		}, {"Sine", "Out", halfDuration}::{any})
		
		-- After shrinking, grow back
		shrinkTween.Completed:Connect(function()
			Functions.Tween(cannonModel, {
				Scale = originalScale
			}, {"Sine", "In", halfDuration}::{any})
		end)
	end)
	
	return muzzleAttachment
end

-- Spawn and animate the projectile
local function spawnProjectile(startAttachment: Attachment, targetPosition: Vector3, travelDuration: number)
	-- Find the PartyCannonAmmo template
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		warn("[Party Client] Assets folder not found")
		return
	end
	
	local adminEvents = assets:FindFirstChild("AdminEvents")
	if not adminEvents then
		warn("[Party Client] AdminEvents folder not found")
		return
	end
	
	local party = adminEvents:FindFirstChild("Party")
	if not party then
		warn("[Party Client] Party folder not found")
		return
	end
	
	local ammoTemplate = party:FindFirstChild("PartyCannonAmmo")
	if not ammoTemplate then
		warn("[Party Client] PartyCannonAmmo not found")
		return
	end
	
	-- Clone the ammo
	local projectile = ammoTemplate:Clone()
	
	-- Find or create __DEBRIS folder
	local debris = Workspace:FindFirstChild("__DEBRIS")
	if not debris then
		debris = Instance.new("Folder")
		debris.Name = "__DEBRIS"
		debris.Parent = Workspace
	end
	
	projectile.Parent = debris
	
	-- Get start position from attachment
	local startPosition = startAttachment.WorldPosition
	
	-- Play cannon ammo spawn sound
	Audio.Play("rbxassetid://104359364272503", startPosition, 1, 1, 150)
	
	-- Calculate Bezier mid point (middle of two positions + 50 Y)
	local midPosition = (startPosition + targetPosition) / 2
	midPosition = Vector3.new(midPosition.X, midPosition.Y + 50, midPosition.Z)
	
	-- Create Bezier curve function
	local bezierFunc, _ = Functions.Bezier(startPosition, midPosition, targetPosition)
	
	-- Animate the projectile
	local elapsed = 0
	local connection: RBXScriptConnection
	
	connection = RunService.RenderStepped:Connect(function(delta)
		elapsed += delta
		local alpha = math.min(elapsed / travelDuration, 1)
		
		if alpha >= 1 then
			-- Animation complete
			connection:Disconnect()
			projectile:Destroy()
		else
			-- Update position using Bezier curve
			local currentPosition = bezierFunc(alpha)
			
			-- Calculate direction by looking ahead on the curve
			local nextAlpha = math.min(alpha + 0.01, 1)
			local nextPosition = bezierFunc(nextAlpha)
			local direction = (nextPosition - currentPosition).Unit
			
			-- Create CFrame that looks in the direction of movement
			local orientedCFrame = CFrame.lookAt(currentPosition, currentPosition + direction)
			
			if projectile.PrimaryPart then
				projectile:PivotTo(orientedCFrame)
			elseif projectile:IsA("BasePart") then
				projectile.CFrame = orientedCFrame
			end
		end
	end)
end

-- Handle party fish spawn animation
local function handlePartyFishSpawn(spawnData: any?)
	if typeof(spawnData) ~= "table" then
		return
	end
	
	local fishData = spawnData :: {
		FishId: string?,
		Type: string?,
		Mutation: string?,
		Position: Vector3?,
		Orientation: Vector3?,
		SpawnTime: number?,
		VisualData: {{FishId: string, Type: string, Mutation: string?}}?,
	}
	
	if not fishData.FishId or not fishData.Position or not fishData.SpawnTime or not fishData.VisualData then
		warn("[Party Client] Invalid fish spawn data")
		return
	end
	
	-- Find PartyFishSpawn tagged part
	local spawnParts = CollectionService:GetTagged("PartyFishSpawn")
	if #spawnParts == 0 then
		warn("[Party Client] No PartyFishSpawn part found, skipping animation")
		return
	end
	
	local spawnPart = spawnParts[1]
	if not spawnPart:IsA("BasePart") then
		warn("[Party Client] PartyFishSpawn is not a BasePart")
		return
	end
	
	-- Get final fish schema
	local finalFishSchema = Directory.Fish[fishData.FishId]
	if not finalFishSchema then
		warn("[Party Client] Fish schema not found:", fishData.FishId)
		return
	end
	
	-- Find or create __DEBRIS folder
	local debris = Workspace:FindFirstChild("__DEBRIS")
	if not debris then
		debris = Instance.new("Folder")
		debris.Name = "__DEBRIS"
		debris.Parent = Workspace
	end
	
	-- Animation parameters
	local animationDuration = 3 -- seconds total for cycling
	
	-- Use visual data from server
	local visualData = assert(fishData.VisualData, "VisualData is required")
	
	-- Calculate variable intervals (fast start, slow end)
	local intervals = {}
	local totalWeight = 0
	
	for i = 1, #visualData do
		local progress = (i - 1) / (#visualData - 1) -- 0 to 1
		local weight = math.exp(progress * 3.5) -- Exponential curve
		intervals[i] = weight
		totalWeight = totalWeight + weight
	end
	
	-- Normalize intervals
	for i = 1, #visualData do
		intervals[i] = (intervals[i] / totalWeight) * animationDuration
	end
	
	task.spawn(function()
		local currentDisplayFish: Model? = nil
		
		-- Cycle through visual data
		for i, visual in ipairs(visualData) do
			-- Clean up previous fish
			if currentDisplayFish then
				currentDisplayFish:Destroy()
				currentDisplayFish = nil
			end
			
			-- Create temporary fish model for this visual
			local fishDir = Directory.Fish[visual.FishId]
			if fishDir and fishDir._script then
				local tempFishModel = fishDir._script:WaitForChild("Model"):Clone() :: Model
				
				-- Apply fish type styling
				local swimmingFishFolder = Workspace:WaitForChild("__THINGS"):WaitForChild("SwimmingFish")
				local parent = swimmingFishFolder
				
				if visual.Type == "Shiny" then
					parent = swimmingFishFolder:WaitForChild("Shiny")
				elseif visual.Type == "Rainbow" then
					parent = swimmingFishFolder:WaitForChild("Rainbow")
				elseif visual.Type == "Gold" then
					parent = swimmingFishFolder:WaitForChild("Gold")
				end
				
				-- Apply mutation if present
				if visual.Mutation then
					local mutationDir = Directory.Mutations[visual.Mutation]
					if mutationDir then
						mutationDir.ApplyToModel(tempFishModel)
					end
				end
				
				-- Position the temporary model at the spawn part position
				tempFishModel:PivotTo(spawnPart.CFrame)
				tempFishModel:SetAttribute("_TempAnimation", true)
				tempFishModel:SetAttribute("PartyFishSpawn", true)
				tempFishModel:AddTag("SwimmingFish")
				
				-- Make fish anchored
				for _, descendant in ipairs(tempFishModel:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.Anchored = true
					end
				end
				
				tempFishModel.Parent = parent
				
				-- Apply Party trait visual effect
				local partyTrait = Directory.Traits["Party"]
				if partyTrait and partyTrait.ApplyToModel then
					partyTrait.ApplyToModel(tempFishModel)
				end
				
				-- Create billboard for this fish
				setupTempBillboard(tempFishModel, visual.FishId, visual.Type, visual.Mutation)
				
				currentDisplayFish = tempFishModel
				
				-- Play reveal sound
				Audio.Play("rbxassetid://73644741132942", spawnPart.Position, 1, 0.5, 150)
			end
			
			-- Wait for interval
			task.wait(intervals[i])
		end
		
		-- Clean up last visual fish
		if currentDisplayFish then
			currentDisplayFish:Destroy()
		end
		
		-- Create final display fish
		local finalFishModelTemplate = finalFishSchema._script:FindFirstChild("Model")
		if not finalFishModelTemplate or not finalFishModelTemplate:IsA("Model") then
			warn("[Party Client] Final fish model not found:", fishData.FishId)
			return
		end
		
		local displayFish = finalFishModelTemplate:Clone() :: Model
		
		-- Apply fish type styling
		local swimmingFishFolder = Workspace:WaitForChild("__THINGS"):WaitForChild("SwimmingFish")
		local parent = swimmingFishFolder
		
		if fishData.Type == "Shiny" then
			parent = swimmingFishFolder:WaitForChild("Shiny")
		elseif fishData.Type == "Rainbow" then
			parent = swimmingFishFolder:WaitForChild("Rainbow")
		elseif fishData.Type == "Gold" then
			parent = swimmingFishFolder:WaitForChild("Gold")
		end
		
		-- Apply mutation if present
		if fishData.Mutation then
			local mutationDir = Directory.Mutations[fishData.Mutation]
			if mutationDir then
				mutationDir.ApplyToModel(displayFish)
			end
		end
		
		-- Position the display fish at the spawn part position
		displayFish:PivotTo(spawnPart.CFrame)
		displayFish:SetAttribute("_TempAnimation", true)
		displayFish:SetAttribute("PartyFishSpawn", true)
		displayFish:AddTag("SwimmingFish")
		
		-- Make fish anchored
		for _, descendant in ipairs(displayFish:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		
		displayFish.Parent = parent
		
		-- Apply Party trait visual effect
		local partyTrait = Directory.Traits["Party"]
		if partyTrait and partyTrait.ApplyToModel then
			partyTrait.ApplyToModel(displayFish)
		end
		
		-- Create billboard for final fish
		setupTempBillboard(displayFish, fishData.FishId, fishData.Type or "Normal", fishData.Mutation)
		
		-- Play final reveal sounds
		Audio.Play("rbxassetid://78632974820364", spawnPart.Position, 1, 1, 150)
		Audio.Play("rbxassetid://81968496022483", spawnPart.Position, 1, 1, 150)
		
		-- Wait 2 seconds before flying
		task.wait(2)
		
		-- Calculate timing for Bezier curve flight
		local currentTime = workspace:GetServerTimeNow()
		local timeUntilSpawn = fishData.SpawnTime - currentTime
		
		if timeUntilSpawn <= 0 then
			warn("[Party Client] Fish spawn time already passed, destroying immediately")
			displayFish:Destroy()
			return
		end
		
		-- Remove SwimmingFish tag before flying
		displayFish:RemoveTag("SwimmingFish")
		
		-- Fly fish to target position using Bezier curve
		local startPosition = displayFish:GetPivot().Position
		local targetPosition = fishData.Position
		
		-- Use Y = 130 as bezier midpoint Y
		local midPosition = (startPosition + targetPosition) / 2
		midPosition = Vector3.new(midPosition.X, 130, midPosition.Z)
		
		-- Create Bezier curve function
		local bezierFunc, _ = Functions.Bezier(startPosition, midPosition, targetPosition)
		
		-- Animate the fish
		local elapsed = 0
		local connection: RBXScriptConnection
		
		connection = RunService.RenderStepped:Connect(function(delta)
			elapsed += delta
			local alpha = math.min(elapsed / timeUntilSpawn, 1)
			
			if alpha >= 1 then
				-- Animation complete, destroy display fish
				connection:Disconnect()
				displayFish:Destroy()
			else
				-- Update position using Bezier curve
				local currentPosition = bezierFunc(alpha)
				
				-- Calculate direction by looking ahead on the curve
				local nextAlpha = math.min(alpha + 0.01, 1)
				local nextPosition = bezierFunc(nextAlpha)
				local direction = (nextPosition - currentPosition).Unit
				
				-- Create CFrame that looks in the direction of movement
				local yaw = math.rad(fishData.Orientation and fishData.Orientation.Y or 0)
				local orientedCFrame = CFrame.new(currentPosition) * CFrame.Angles(0, yaw, 0) * CFrame.lookAt(Vector3.zero, direction)
				
				displayFish:PivotTo(orientedCFrame)
			end
		end)
	end)
end

function module.OnStart()
	print("[Party Client] Event started")
	_isActive = true
	
	NotificationCmds.Message("Let's party! 🎉", {
		Color = Color3.fromRGB(255, 100, 255),
		Time = 8,
		Sound = "rbxassetid://96756442780379"
	})
	
	-- Play party start sound at PartyFishSpawn part
	local spawnParts = CollectionService:GetTagged("PartyFishSpawn")
	if #spawnParts > 0 and spawnParts[1]:IsA("BasePart") then
		Audio.Play("rbxassetid://116222140946445", (spawnParts[1] :: BasePart).Position, 1, 1, 150)
	end
	
	-- Setup TagHook to listen for PartyCannon models
	Functions.TagHook("PartyCannon", function(inst: Instance)
		if inst and inst:IsA("Model") then
			setupCannon(inst)
		end
		
		-- Cleanup function
		return function()
			local cannonId = inst:GetAttribute("Id")
			if typeof(cannonId) == "number" and cannons[cannonId] == inst then
				cannons[cannonId] = nil
				print(`[Party Client] Unregistered cannon {cannonId}`)
			end
		end
	end)
	
	-- Register handler for party cannon shots
	AdminAbuseEventCmds.Fired("Party", "Shoot", function(data: any?)
		if typeof(data) == "table" then
			local shootData = data :: {
				UID: string?,
				CannonId: number?,
				TargetPosition: Vector3?,
				TraitApplyTime: number?
			}
			
			if not shootData.CannonId or not shootData.TargetPosition or not shootData.TraitApplyTime then
				return
			end
			
			local cannon = cannons[shootData.CannonId]
			if not cannon then
				warn(`[Party Client] Cannon {shootData.CannonId} not found`)
				return
			end
			
			local currentTime = workspace:GetServerTimeNow()
			local totalDuration = shootData.TraitApplyTime - currentTime
			
			if totalDuration <= 0 then
				warn("[Party Client] TraitApplyTime is in the past")
				return
			end
			
			-- 5% of time for aiming
			local aimDuration = totalDuration * 0.05
			-- 10% of time for cannon animation (shrink/grow)
			local cannonAnimDuration = totalDuration * 0.1
			-- 85% of time for projectile travel
			local projectileTravelDuration = totalDuration * 0.85
			
			-- Calculate the bezier curve trajectory to determine aim direction
			-- Find the ShootPart to get the muzzle position
			local shootPart = cannon:FindFirstChild("ShootPart")
			if not shootPart or not shootPart:IsA("Model") then
				warn("[Party Client] ShootPart not found in cannon for aiming calculation")
				return
			end
			
			local primaryPart = shootPart.PrimaryPart
			if not primaryPart then
				warn("[Party Client] ShootPart has no PrimaryPart for aiming calculation")
				return
			end
			
			local muzzleAttachment = primaryPart:FindFirstChild("Muzzle")
			if not muzzleAttachment or not muzzleAttachment:IsA("Attachment") then
				warn("[Party Client] Muzzle attachment not found for aiming calculation")
				return
			end
			
			-- Calculate bezier curve points
			local startPosition = muzzleAttachment.WorldPosition
			local targetPosition = shootData.TargetPosition
			local midPosition = (startPosition + targetPosition) / 2
			midPosition = Vector3.new(midPosition.X, midPosition.Y + 50, midPosition.Z)
			
			-- Create bezier curve function
			local bezierFunc, _ = Functions.Bezier(startPosition, midPosition, targetPosition)
			
			-- Get position 10% along the curve for aiming
			local aimTargetPosition = bezierFunc(0.1)
			
			-- Start cannon animation (aiming + shrink/grow)
			local totalCannonTime = aimDuration + cannonAnimDuration
			local finalMuzzleAttachment = animateCannon(cannon, aimDuration, cannonAnimDuration, aimTargetPosition)
			
			if finalMuzzleAttachment then
				-- Wait for all cannon animations to complete
				task.delay(totalCannonTime, function()
					-- Spawn and animate projectile
					spawnProjectile(finalMuzzleAttachment, targetPosition, projectileTravelDuration)
				end)
			end
		end
	end)
	
	-- Register handler for party fish spawns
	AdminAbuseEventCmds.Fired("Party", "FishSpawn", function(data: any?)
		handlePartyFishSpawn(data)
	end)
end

function module.RenderStepped(delta: number, time: number)
	-- No continuous rendering needed for this event
end

function module.OnStop()
	print("[Party Client] Event stopped")
	_isActive = false
	
	NotificationCmds.Message("Party's over! 🎈", {
		Color = Color3.fromRGB(255, 100, 255),
		Time = 8,
	})
	
	-- Play party end sound at PartyFishSpawn part
	local spawnParts = CollectionService:GetTagged("PartyFishSpawn")
	if #spawnParts > 0 and spawnParts[1]:IsA("BasePart") then
		Audio.Play("rbxassetid://135729759317677", (spawnParts[1] :: BasePart).Position, 1, 1, 150)
	end
	
	-- Clear cannons
	cannons = {}
end

return module

