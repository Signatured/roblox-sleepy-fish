--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Huge",
	CanTarget = true,
	Cooldown = 90,
	Duration = 30,
	OnExecute = function(executor: Player, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local target = targetPlayer or executor
        local character = Player.Optional.Character(target)

		if not character then
			return false, `You cannot do that right now!`
		end

		character:ScaleTo(5)
		
		-- Return success and finish function
		return true, function()
			character:ScaleTo(1)
		end
	end,
}

return Spin
