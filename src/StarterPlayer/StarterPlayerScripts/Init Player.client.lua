--!strict

local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Network = require(game.ReplicatedStorage.Library.Client.Network)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

local Player = require(game.ReplicatedStorage.Library.Player)

local localPlayer = Players.LocalPlayer

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

local function disableReset()
    -- Disable the Reset Character button in the escape menu
    local ok = pcall(function()
        StarterGui:SetCore("ResetButtonCallback", false)
    end)
    
    if not ok then
        task.wait(1)
        task.defer(disableReset)
    else
        StarterGui:SetCore("ResetButtonCallback", false)
    end
end

local function platformStandDisable()
    task.spawn(function()
        while task.wait(4) do
            local flying = localPlayer:GetAttribute("Flying")
            local humanoid = Player.Optional.Humanoid()
            if humanoid and not flying then
                humanoid.PlatformStand = false
            end
        end
    end)
end

disableReset()
platformStandDisable()

-- After 5 minutes of playtime in this session, prompt to enable notifications (if allowed)
task.delay(300, function()
	-- Function to check whether the player can be prompted to enable notifications
	local function canPromptOptIn(): boolean
		local success, canPrompt = pcall(function()
			return ExperienceNotificationService:CanPromptOptInAsync()
		end)
		return success and (canPrompt == true)
	end

    local save = Save.Get()
    if not save or save.PromptedNotifications then
        return
    end

	local canPrompt = canPromptOptIn()
	if canPrompt then
		pcall(function()
			ExperienceNotificationService:PromptOptIn()
            Network.Fire("PromptedNotifications")
		end)
	end
end)