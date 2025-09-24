--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Tiny",
	CanTarget = true,
	Cooldown = 10,
	OnExecute = function(executor: Player, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local target = targetPlayer or executor
        local character = Player.Optional.Character(target)

		if not character then
			return false, `You cannot do that right now!`
		end

		local scale = character:GetScale()
		if scale <= 0.1 then
			return false, `{target.Name} is already smallest size!`
		end

		if scale > 1 then
			scale = 1
		else
			scale = math.max(scale - 0.2, 0.1)
		end

		character:ScaleTo(scale)
		
		-- Return success and finish function
		return true, function()
		end
	end,
}

return Spin
