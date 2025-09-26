--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Functions = require(game.ReplicatedStorage.Library.Functions)

local DANCE_IDS = {
    "rbxassetid://137727097461722", -- breakdown
    "rbxassetid://104778822344187", -- calamity
    "rbxassetid://87907484596907", -- fancy feet
    "rbxassetid://114369284080599", -- flapper
    "rbxassetid://123325041249112", -- floss
    "rbxassetid://76115383172289", -- free flow
    "rbxassetid://87773403736380", -- orange justice
    "rbxassetid://119217185534841", -- ride the mony
    "rbxassetid://97654799159746", -- smooth moves
    "rbxassetid://89158667135898", -- the robot
}

local Spin: AdminPanelTypes.AdminCommand = {
	DisplayName = "Dance",
	Icon = "rbxassetid://136314566712324",
	TargetMessage = "<name> made you dance with Admin Panel!",
	CanTarget = true,
	Cooldown = 60,
	Duration = 30,
	OnExecute = function(executor: Player?, targetPlayer: Player?): (boolean, (string | (() -> ()))?)
		local Network = require(game.ServerScriptService.Library.Network)
		
        local target = targetPlayer or executor
        
        -- If executor is nil (console) and no target specified, return error
        if not target then
            return false, "Console command requires a target player"
        end
        
		if target:GetAttribute("Dancing") then
			return false, `{target.Name} is already dancing!`
		end

		target:SetAttribute("Dancing", true)

		local randomAnimationId = DANCE_IDS[math.random(1, #DANCE_IDS)]

		local animation = Functions.Animation(randomAnimationId, target, 1, true)

		task.spawn(function()
			for i = 1, 5 do
				Network.Fire(target, "Confetti")
				task.wait(2)
			end
		end)

		-- Return success and finish function
		return true, function()
			target:SetAttribute("Dancing", nil)
			animation:Stop(0.3)

			task.delay(0.5, function()
				animation:Destroy()
			end)
		end
	end,
}

return Spin
