--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Spin",
	CanTarget = true,
	Cooldown = 5,
	Duration = 3, -- Spin for 3 seconds before stopping
	OnExecute = function(executor: Player, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
		local target = targetPlayer or executor
        local head = Player.Optional.Head(target)
        local spinRate = 20
        
        if not head then
            return false, `You cannot do that right now!`
        end
        
        local spin1 = head:FindFirstChild("Spin1") :: BodyAngularVelocity?
        local spin2 = head:FindFirstChild("Spin2") :: BodyGyro?

        if spin1 or spin2 then
            return false, `{target.Name} is already spinning!`
        end
        
        if not spin1 then
            spin1 = Instance.new("BodyAngularVelocity") :: BodyAngularVelocity
            assert(spin1)
            spin1.MaxTorque = Vector3.new(300000, 300000, 300000)
            spin1.P = 300
            spin1.Name = "Spin1"
            spin1.Parent = head
            
            spin2 = Instance.new("BodyGyro") :: BodyGyro
            assert(spin2)
            spin2.MaxTorque = Vector3.new(400000, 0, 400000)
            spin2.D = 500
            spin2.P = 300
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
