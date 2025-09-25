--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Ragdoll: AdminPanelTypes.AdminCommand = {
	DisplayName = "Ragdoll",
	CanTarget = true,
	Cooldown = 120,
	Duration = 6,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
		local target = targetPlayer or executor
		
		-- If executor is nil (console) and no target specified, return error
		if not target then
			return false, "Console command requires a target player"
		end
		local character = Player.Optional.Character(target)
		local humanoid = Player.Optional.Humanoid(target)
		local humanoidRootPart = Player.Optional.HumanoidRootPart(target)

		-- Check if target can be ragdolled
		if not character or not humanoid or not humanoidRootPart or humanoid.Health <= 0 then
			return false, "Target cannot be ragdolled right now!"
		end

		-- Check if already ragdolled
		if target:GetAttribute("Ragdolled") then
			return false, `{target.Name} is already ragdolled!`
		end

		-- Mark as ragdolled
		target:SetAttribute("Ragdolled", true)

		-- Store original humanoid states
		local originalPlatformStand = humanoid.PlatformStand
		local originalJumpPower = humanoid.JumpPower
		local originalWalkSpeed = humanoid.WalkSpeed
		local originalJumpHeight = humanoid.JumpHeight
		local originalSit = humanoid.Sit

		-- Disable humanoid control completely
		humanoid.PlatformStand = true
		humanoid.JumpPower = 0
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.Sit = true
		
		-- Disable all humanoid states to prevent control
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

		-- Create a loop to continuously enforce ragdoll state
		local ragdollLoop = task.spawn(function()
			while target:GetAttribute("Ragdolled") do
				local currentHumanoid = Player.Optional.Humanoid(target)
				if currentHumanoid then
					-- Continuously enforce disabled control
					currentHumanoid.PlatformStand = true
					currentHumanoid.JumpPower = 0
					currentHumanoid.WalkSpeed = 0
					currentHumanoid.JumpHeight = 0
					currentHumanoid.Sit = true
					
					-- Re-disable states that might get re-enabled
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
					currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
					
					-- Force physics state if humanoid tries to change
					if currentHumanoid:GetState() ~= Enum.HumanoidStateType.Physics then
						currentHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
					end
				end
				task.wait(0.1) -- Check every 0.1 seconds
			end
		end)

		-- Convert Motor6D joints to BallSocketConstraints for ragdoll effect
		local joints = {}
		local ballSocketConstraints = {}
		
		-- Store ragdoll loop reference for cleanup
		local ragdollLoopRef = ragdollLoop

		for _, joint in pairs(character:GetDescendants()) do
			if joint:IsA("Motor6D") then
				local part0 = joint.Part0
				local part1 = joint.Part1
				
				if part0 and part1 then
					-- Store original joint data
					table.insert(joints, {
						joint = joint,
						part0 = part0,
						part1 = part1,
						c0 = joint.C0,
						c1 = joint.C1
					})

					-- Create BallSocketConstraint for ragdoll physics
					local ballSocket = Instance.new("BallSocketConstraint")
					
					-- Find or create attachment for Part0
					local attachment0: Attachment
					local existingAttachment0 = part0:FindFirstChild(joint.Name .. "RigAttachment") or 
												part0:FindFirstChild("RootRigAttachment") or
												part0:FindFirstChildOfClass("Attachment")
					
					if existingAttachment0 and existingAttachment0:IsA("Attachment") then
						attachment0 = existingAttachment0 :: Attachment
					else
						attachment0 = Instance.new("Attachment")
						attachment0.Name = "RagdollAttachment0"
						attachment0.CFrame = joint.C0
						attachment0.Parent = part0
					end
					
					-- Find or create attachment for Part1
					local attachment1: Attachment
					local existingAttachment1 = part1:FindFirstChild(joint.Name .. "RigAttachment") or
												part1:FindFirstChildOfClass("Attachment")
					
					if existingAttachment1 and existingAttachment1:IsA("Attachment") then
						attachment1 = existingAttachment1 :: Attachment
					else
						attachment1 = Instance.new("Attachment")
						attachment1.Name = "RagdollAttachment1"
						attachment1.CFrame = joint.C1
						attachment1.Parent = part1
					end

					ballSocket.Attachment0 = attachment0
					ballSocket.Attachment1 = attachment1
					
					-- Limit rotation to make joints less floppy
					ballSocket.LimitsEnabled = true
					ballSocket.UpperAngle = 45 -- Maximum 45 degrees rotation
					ballSocket.TwistLimitsEnabled = true
					ballSocket.TwistLowerAngle = -30
					ballSocket.TwistUpperAngle = 30
					
					ballSocket.Parent = part0
					table.insert(ballSocketConstraints, ballSocket)

					-- Disable the motor joint
					joint.Enabled = false
				end
			end
		end

		-- Return success and finish function
		return true, function()
			-- Remove ragdoll attribute (this will stop the ragdoll loop)
			target:SetAttribute("Ragdolled", nil)
			
			-- Cancel the ragdoll enforcement loop
			if ragdollLoopRef then
				task.cancel(ragdollLoopRef)
			end

			-- Check if character still exists
			local currentCharacter = Player.Optional.Character(target)
			local currentHumanoid = Player.Optional.Humanoid(target)
			
			if not currentCharacter or not currentHumanoid then
				return -- Player respawned or left
			end

			-- Restore humanoid control
			currentHumanoid.PlatformStand = originalPlatformStand
			currentHumanoid.JumpPower = originalJumpPower
			currentHumanoid.WalkSpeed = originalWalkSpeed
			currentHumanoid.JumpHeight = originalJumpHeight
			currentHumanoid.Sit = originalSit
			
			-- Re-enable all humanoid states
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)

			-- Remove BallSocketConstraints
			for _, constraint in ipairs(ballSocketConstraints) do
				if constraint.Parent then
					constraint:Destroy()
				end
			end

			-- Re-enable Motor6D joints
			for _, jointData in ipairs(joints) do
				if jointData.joint.Parent then
					jointData.joint.Enabled = true
				end
			end

			-- Clean up any created attachments
			for _, part in pairs(currentCharacter:GetChildren()) do
				if part:IsA("BasePart") then
					for _, attachment in pairs(part:GetChildren()) do
						if attachment:IsA("Attachment") and attachment.Name:find("Ragdoll") then
							attachment:Destroy()
						end
					end
				end
			end
		end
	end,
}

return Ragdoll
