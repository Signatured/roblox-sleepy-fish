--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Explode",
	Icon = "rbxassetid://138874735510748",
	TargetMessage = "You were exploded by <name> with Admin Panel!",
	CanTarget = true,
	Cooldown = 120,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local target = targetPlayer or executor
        
        -- If executor is nil (console) and no target specified, return error
        if not target then
            return false, "Console command requires a target player"
        end
        local hrp = Player.Optional.HumanoidRootPart(target)
        local humanoid = Player.Optional.Humanoid(target)
        local character = Player.Optional.Character(target)

        if not character or not hrp or not humanoid or humanoid.Health <= 0 then
            return false, `You cannot do that right now!`
        end

		if hrp then
			-- Visual-only explosion at the HRP with no physical impact on the world
			local explosion = Instance.new("Explosion")
			explosion.Position = hrp.Position
			explosion.BlastPressure = 0 -- no force applied to anything
			explosion.BlastRadius = 8 -- visual size only
			explosion.Parent = workspace

			-- Do a custom gib without using DestroyJointRadiusPercent to avoid affecting nearby things
			humanoid.BreakJointsOnDeath = false
			local rng = Random.new()
			local _origin = hrp.Position

			-- Detach limbs by removing joints on the character only
			for _, inst in ipairs(character:GetDescendants()) do
				if inst:IsA("Motor6D") or inst:IsA("Weld") or inst:IsA("WeldConstraint") then
					inst:Destroy()
				end
			end

			-- Ensure parts are unanchored and apply impulses to fling pieces away in random directions
			for _, inst in ipairs(character:GetDescendants()) do
				if inst:IsA("BasePart") then
					local part = inst :: BasePart
					part.Anchored = false
					local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.25, 1), rng:NextNumber(-1, 1))
					if dir.Magnitude < 1e-3 then
						dir = Vector3.new(0, 1, 0)
					end
					dir = dir.Unit
					local linearImpulse = part.AssemblyMass * rng:NextNumber(30, 70)
					part:ApplyImpulse(dir * linearImpulse)
					local angularImpulse = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit * part.AssemblyMass * rng:NextNumber(60, 140)
					part:ApplyAngularImpulse(angularImpulse)
				end
			end

			-- Extra upward impulse to send the head flying upward dramatically
			local head = character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local headPart = head :: BasePart
				headPart.Anchored = false
				local upward = Vector3.new(0, 1, 0)
				local headImpulse = headPart.AssemblyMass * rng:NextNumber(350, 600)
				headPart:ApplyImpulse(upward * headImpulse)
				local headSpin = Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5)).Unit * headPart.AssemblyMass * rng:NextNumber(40, 100)
				headPart:ApplyAngularImpulse(headSpin)
			end

			-- Finally, kill the humanoid so the character dies without breaking joints globally
			humanoid.Health = 0
		end
		
		-- Return success and finish function
		return true, function()
			
		end
	end,
}

return Spin
