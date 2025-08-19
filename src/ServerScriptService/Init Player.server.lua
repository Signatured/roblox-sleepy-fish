--!strict

local Players = game:GetService("Players")

local BadgeManager = require(game.ServerScriptService.Game.Library.BadgeManager)

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        BadgeManager.GiveBadgeByName(player, "Welcome")
    end)
end)