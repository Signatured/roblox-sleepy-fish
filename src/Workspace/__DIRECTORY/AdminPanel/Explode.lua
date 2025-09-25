--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Explode",
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
			local explosion = Instance.new("Explosion")
			explosion.Position = hrp.Position
			explosion.Parent = character
			explosion.DestroyJointRadiusPercent = 0.2

			humanoid.Health = 0
		end
		
		-- Return success and finish function
		return true, function()
			
		end
	end,
}

return Spin
