--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)

local Jumpscare: AdminPanelTypes.AdminCommand = {
	DisplayName = "Jumpscare",
	TargetMessage = "You were jumpscared by <name> with Admin Panel!",
	CanTarget = true,
	Cooldown = 90,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local Network = require(game.ServerScriptService.Library.Network)
		local target = targetPlayer or executor
		
		-- If executor is nil (console) and no target specified, return error
		if not target then
			return false, "Console command requires a target player"
		end

		-- Fire the jumpscare event to the target player
		Network.Fire(target, "AdminPanel_Jumpscare")
		
		-- Return success and finish function
		return true, function()
			-- No cleanup needed for jumpscare
		end
	end,
}

return Jumpscare
