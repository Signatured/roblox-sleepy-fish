--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)

local Jumpscare: AdminPanelTypes.AdminCommand = {
	DisplayName = "Jumpscare",
	CanTarget = true,
	Cooldown = 5,
	OnExecute = function(executor: Player, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local Network = require(game.ServerScriptService.Library.Network)
		local target = targetPlayer or executor

		-- Fire the jumpscare event to the target player
		Network.Fire(target, "AdminPanel_Jumpscare")
		
		-- Return success and finish function
		return true, function()
			-- No cleanup needed for jumpscare
		end
	end,
}

return Jumpscare
