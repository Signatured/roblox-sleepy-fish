--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Fling: AdminPanelTypes.AdminCommand = {
	DisplayName = "Fling",
	CanTarget = true,
	Cooldown = 2,
    Duration = 2,
	OnExecute = function(executor: Player, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
		local target = targetPlayer or executor
		local targetHRP = Player.Optional.HumanoidRootPart(target)
		local targetHumanoid = Player.Optional.Humanoid(target)
		local targetCharacter = Player.Optional.Character(target)
		
		-- Check if target can be flung
		if not targetCharacter or not targetHRP or not targetHumanoid or targetHumanoid.Health <= 0 then
			return false, "Target cannot be flung right now!"
		end
		
        target:SetAttribute("Flinged", true)

		-- Store original humanoid states for restoration
		local originalPlatformStand = targetHumanoid.PlatformStand
		local originalJumpPower = targetHumanoid.JumpPower
		local originalWalkSpeed = targetHumanoid.WalkSpeed
		local originalJumpHeight = targetHumanoid.JumpHeight
		
		-- Put humanoid in physics state for ragdoll effect during fling
		targetHumanoid.PlatformStand = true
		targetHumanoid.JumpPower = 0
		targetHumanoid.WalkSpeed = 0
		targetHumanoid.JumpHeight = 0
		targetHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
		
		-- Disable humanoid states to prevent control during fling
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		targetHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		
		-- Calculate fling direction
		local direction: Vector3
		
		if target == executor then
			-- Self-fling: use random direction
			local randomAngle = math.random() * math.pi * 2
			direction = Vector3.new(math.cos(randomAngle), 0, math.sin(randomAngle))
		else
			-- Fling away from executor
			local executorHRP = Player.Optional.HumanoidRootPart(executor)
			if not executorHRP then
				-- Fallback to random direction if executor has no HRP
				local randomAngle = math.random() * math.pi * 2
				direction = Vector3.new(math.cos(randomAngle), 0, math.sin(randomAngle))
			else
				-- Calculate direction from executor to target
				direction = (targetHRP.Position - executorHRP.Position).Unit
			end
		end
		
		-- Add upward component to the direction
		-- Normalize horizontal direction, then add vertical component
		local horizontalDirection = Vector3.new(direction.X, 0, direction.Z).Unit
		local flingDirection = (horizontalDirection * 0.8 + Vector3.new(0, 0.6, 0)).Unit
		
		-- Calculate velocity to fling approximately 50 studs
		-- Using physics: distance = velocity * time (with some adjustment for air resistance)
		local flingPower = 150 -- Adjust this to change fling distance
		local flingVelocity = flingDirection * flingPower
		
		-- Create BodyVelocity to apply the fling
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVelocity.Velocity = flingVelocity
		bodyVelocity.Parent = targetHRP
		
		-- Apply random BodyAngularVelocity for chaotic tumbling effect
		local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
		bodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
		-- Random rotation on all axes for chaotic tumbling
		bodyAngularVelocity.AngularVelocity = Vector3.new(
			math.random(-15, 15), -- X axis rotation (pitch)
			math.random(-15, 15), -- Y axis rotation (yaw) 
			math.random(-15, 15)  -- Z axis rotation (roll)
		)
		bodyAngularVelocity.Parent = targetHRP
		
		-- Remove the body movers after a short time to let physics take over
		task.delay(0.3, function()
			if bodyVelocity and bodyVelocity.Parent then
				bodyVelocity:Destroy()
			end
			if bodyAngularVelocity and bodyAngularVelocity.Parent then
				bodyAngularVelocity:Destroy()
			end
		end)
		return true, function()
			target:SetAttribute("Flinged", nil)

            -- Check if humanoid still exists
			local currentHumanoid = Player.Optional.Humanoid(target)
			if not currentHumanoid then
				return -- Player respawned or left
			end
			
			-- Restore humanoid states
			currentHumanoid.PlatformStand = originalPlatformStand
			currentHumanoid.JumpPower = originalJumpPower
			currentHumanoid.WalkSpeed = originalWalkSpeed
			currentHumanoid.JumpHeight = originalJumpHeight
			
			-- Re-enable all humanoid states
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end,
}

return Fling
