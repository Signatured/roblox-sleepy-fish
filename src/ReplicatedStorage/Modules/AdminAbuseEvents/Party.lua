--!strict

--[[
	Client-side logic for Party event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local AdminAbuseEventCmds = require(ReplicatedStorage.Game.Library.Client.AdminAbuseEventCmds)
local Functions = require(ReplicatedStorage.Library.Functions)

local module = {}

-- Shared state for this event
local cannons: {[number]: Model} = {}
local _isActive = false

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

function module.OnStart()
	print("[Party Client] Event started")
	_isActive = true
	
	NotificationCmds.Message("Let's party! 🎉", {
		Color = Color3.fromRGB(255, 100, 255),
		Time = 8,
	})
	
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
	
	-- Clear cannons
	cannons = {}
end

return module

