--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Teleport: AdminPanelTypes.AdminCommand = {
	DisplayName = "Teleport",
	Icon = "rbxassetid://137300143220984",
	TargetMessage = "<name> teleported to you with Admin Panel!",
	CanTarget = true,
	Cooldown = 90,
	PreventGlobal = true,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
		-- Console execution cannot teleport (no executor to move)
		if not executor then
			return false, "Console cannot use teleport command (no executor to teleport)"
		end
		
		-- Need a target to teleport to
		if not targetPlayer then
			return false, "You need to select a target player to teleport to!"
		end
		
		local executorHRP = Player.Optional.HumanoidRootPart(executor)
		local executorCharacter = Player.Optional.Character(executor)
		local executorHumanoid = Player.Optional.Humanoid(executor)
		
		local targetHRP = Player.Optional.HumanoidRootPart(targetPlayer)
		local targetCharacter = Player.Optional.Character(targetPlayer)
		local targetHumanoid = Player.Optional.Humanoid(targetPlayer)

		-- Check if executor can be teleported
		if not executorCharacter or not executorHRP or not executorHumanoid or executorHumanoid.Health <= 0 then
			return false, "You cannot teleport right now!"
		end
		
		-- Check if target exists and is alive
		if not targetCharacter or not targetHRP or not targetHumanoid or targetHumanoid.Health <= 0 then
			return false, `{targetPlayer.Name} cannot be teleported to right now!`
		end

		-- Calculate teleport position (slightly behind the target to avoid overlapping)
		local targetPosition = targetHRP.Position
		local targetLookVector = targetHRP.CFrame.LookVector
		local teleportPosition = targetPosition - (targetLookVector * 5) -- 5 studs behind target
		
		-- Create CFrame that positions executor behind target and makes them face the target
		local teleportCFrame = CFrame.lookAt(teleportPosition, targetPosition)
		
		-- Use PivotTo to teleport the executor's character
		executorCharacter:PivotTo(teleportCFrame)
		
		-- Return success and finish function
		return true, function()
			-- No cleanup needed for teleport
		end
	end,
}

return Teleport
