--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Network = require(game.ServerScriptService.Library.Network)

local allowedStages = {
    ["GoToWater"] = 1,
    ["FindClownFish"] = 2,
    ["ReturnToWaterWithFish"] = 3,
    ["FindEmptyPedestal"] = 4,
    ["PointClaim"] = 5,
    ["PointToUpgradeButton"] = 6,
    ["BuyTool"] = 7,
    ["Complete"] = 8,
}

local playerStages: {[Player]: {[string]: boolean}} = {}

Network.Fired("TutorialStage", function(player: Player, stage: string)
    if RunService:IsStudio() then
        return
    end

    local stepNum = allowedStages[stage]
    if not stepNum then
        return
    end

    if not playerStages[player] then
        playerStages[player] = {}
    end

    if playerStages[player][stage] then
        return
    end

    playerStages[player][stage] = true

    AnalyticsService:LogOnboardingFunnelStepEvent(
        player,
        stepNum, -- Step number
        "Tutorial_" .. stage -- Step name
    )
end)

Players.PlayerAdded:Connect(function(player)
    playerStages[player.UserId] = {}
end)

Players.PlayerRemoving:Connect(function(player)
    playerStages[player.UserId] = nil
end)