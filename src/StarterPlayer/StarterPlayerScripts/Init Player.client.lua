--!strict

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

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
                print("disabled")
            end
        end
    end)
end

disableReset()
platformStandDisable()