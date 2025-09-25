--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Player = require(game.ReplicatedStorage.Library.Player)

local Assets = game.ReplicatedStorage.Assets

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Jail",
	CanTarget = true,
	Cooldown = 120,
	Duration = 10,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
        local target = targetPlayer or executor
        
        -- If executor is nil (console) and no target specified, return error
        if not target then
            return false, "Console command requires a target player"
        end
        local hrp = Player.Optional.HumanoidRootPart(target)
        local humanoid = Player.Optional.Humanoid(target)

        if target:GetAttribute("Jailed") then
            return false, `{target.Name} is already jailed!`
        end

        target:SetAttribute("Jailed", true)

		local jail = Assets.Models.Jail:Clone()
		
		-- Position jail at target's feet or HRP if swimming
		if hrp and jail.PrimaryPart and humanoid then
			if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
				-- If swimming, center jail on player's HRP position
				jail:PivotTo(CFrame.new(hrp.Position - Vector3.new(0, 4, 0)))
			else
				-- Get the target's foot position (bottom of HumanoidRootPart)
				local targetFeetPosition = hrp.Position - Vector3.new(0, hrp.Size.Y / 2, 0)
				
				-- Calculate jail position so its top aligns with target's feet
				local jailTopOffset = jail.PrimaryPart.Size.Y / 2
				local jailPosition = targetFeetPosition - Vector3.new(0, jailTopOffset, 0)
				
				-- Set the jail's position
				jail:PivotTo(CFrame.new(jailPosition))
			end
		end
		
		-- Parent the jail to workspace
		jail.Parent = workspace.__DEBRIS
		
		-- Return success and finish function
		return true, function()
			target:SetAttribute("Jailed", nil)
			jail:Destroy()
		end
	end,
}

return Spin
