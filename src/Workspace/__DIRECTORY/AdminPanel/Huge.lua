--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Huge",
	CanTarget = true,
	Cooldown = 10,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local target = targetPlayer or executor
        
        -- If executor is nil (console) and no target specified, return error
        if not target then
            return false, "Console command requires a target player"
        end
        local character = Player.Optional.Character(target)

		if not character then
			return false, `You cannot do that right now!`
		end

		local scale = character:GetScale()
		if scale >= 8 then
			return false, `{target.Name} is already max size!`
		end

		if scale < 0.1 then
			scale = 1
		else
			scale = scale + 2
		end

		character:ScaleTo(scale)
		
		-- Return success and finish function
		return true, function()
			
		end
	end,
}

return Spin
