--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Spin",
    Icon = "rbxassetid://108891687436150",
	TargetMessage = "You were spun by <name> with Admin Panel!",
	CanTarget = true,
	Cooldown = 45,
	Duration = 10,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
		local target = targetPlayer or executor
		
		-- If executor is nil (console) and no target specified, return error
		if not target then
			return false, "Console command requires a target player"
		end
        local head = Player.Optional.Head(target)
        local humanoid = Player.Optional.Humanoid(target)
        local hrp = Player.Optional.HumanoidRootPart(target)
        local spinRate = 20
        
        if not head or not humanoid or not hrp then
            return false, `You cannot do that right now!`
        end
        
        -- Use HumanoidRootPart mass for more accurate scaling
        local currentMass = hrp.AssemblyMass
        local defaultMass = 16 -- Approximate default character mass
        local massRatio = currentMass / defaultMass
        
        -- Extremely aggressive scaling - mass can be 100x+ larger for big characters
        local torqueMultiplier = math.max(1, massRatio * 50)
        
        local spin1 = head:FindFirstChild("Spin1") :: BodyAngularVelocity?
        local spin2 = head:FindFirstChild("Spin2") :: BodyGyro?

        if spin1 or spin2 then
            return false, `{target.Name} is already spinning!`
        end
        
        if not spin1 then
            spin1 = Instance.new("BodyAngularVelocity") :: BodyAngularVelocity
            assert(spin1)
            spin1.MaxTorque = Vector3.new(300000, 300000, 300000) * torqueMultiplier
            spin1.P = 300 * torqueMultiplier
            spin1.Name = "Spin1"
            spin1.Parent = head
            
            spin2 = Instance.new("BodyGyro") :: BodyGyro
            assert(spin2)
            spin2.MaxTorque = Vector3.new(400000, 0, 400000) * torqueMultiplier
            spin2.D = 500 * torqueMultiplier
            spin2.P = 300 * torqueMultiplier
            spin2.Name = "Spin2"
            spin2.Parent = head
        end
        
        if spin1 then
            spin1.AngularVelocity = Vector3.new(0, spinRate, 0)
        end
		
		-- Return success and finish function
		return true, function()
			local head = Player.Head(target)
			if head then
				local spin1 = head:FindFirstChild("Spin1")
				local spin2 = head:FindFirstChild("Spin2")
				if spin1 then
					spin1:Destroy()
				end
				if spin2 then
					spin2:Destroy()
				end
			end
		end
	end,
}

return Spin
