--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)
local Functions = require(game.ReplicatedStorage.Library.Functions)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Fling",
	CanTarget = true,
	Cooldown = 5,
	Duration = 5, -- Spin for 3 seconds before stopping
	OnExecute = function(executor: Player, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local target = targetPlayer or executor
        local targetHrp = Player.Optional.HumanoidRootPart(target)
        local targetHumanoid = Player.Optional.Humanoid(target)

        if not targetHrp or not targetHumanoid then
            return false, `You cannot do that right now!`
        end

        -- Check if already being flung
        if targetHrp:FindFirstChild("FlingVelocity") then
            return false, `{target.Name} is already being flung!`
        end

        -- Calculate fling direction
        local direction: Vector3
        if not targetPlayer then
            -- Self-targeting: fling forward
            direction = targetHrp.CFrame.LookVector
        else
            -- Targeting another player: fling away from executor
            local executorHrp = Player.Optional.HumanoidRootPart(executor)
            if not executorHrp then
                return false, `You cannot do that right now!`
            end
            direction = (targetHrp.Position - executorHrp.Position).Unit
        end

        -- Create BodyPosition with extreme upward target for reliable flinging
        local bodyPosition = Instance.new("BodyPosition")
        bodyPosition.Name = "FlingVelocity"
        bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyPosition.P = 20000
        bodyPosition.D = 2000
        
        -- Set target position very high up and forward
        local targetPosition = targetHrp.Position + direction * 100 + Vector3.new(0, 1000, 0)
        bodyPosition.Position = targetPosition
        bodyPosition.Parent = targetHrp

        -- Add spinning effect
        local spin = Instance.new("BodyAngularVelocity")
        spin.Name = "FlingSpin"
        spin.MaxTorque = Vector3.new(50000, 50000, 50000)
        spin.AngularVelocity = Vector3.new(
            math.random(-15, 15),
            math.random(-15, 15),
            math.random(-15, 15)
        )
        spin.Parent = targetHrp

        -- Disable character control temporarily
        targetHumanoid.PlatformStand = true

        -- Clean up after a very short time (just enough to launch)
        Functions.AddDebris(bodyPosition, 0.15)
        Functions.AddDebris(spin, 1.0)
		
		-- Return success and finish function
		return true, function()
            if targetHumanoid and targetHumanoid.Parent then
                targetHumanoid.PlatformStand = false
            end
            
            -- Clean up any remaining fling objects
            local remainingPosition = targetHrp:FindFirstChild("FlingVelocity")
            local remainingSpin = targetHrp:FindFirstChild("FlingSpin")
            if remainingPosition then
                remainingPosition:Destroy()
            end
            if remainingSpin then
                remainingSpin:Destroy()
            end
		end
	end,
}

return Spin
