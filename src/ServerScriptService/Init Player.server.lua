--!strict

local Players = game:GetService("Players")

local Saving = require(game.ServerScriptService.Library.Saving)
local BadgeManager = require(game.ServerScriptService.Game.Library.BadgeManager)
local Network = require(game.ServerScriptService.Library.Network)

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        BadgeManager.GiveBadgeByName(player, "Welcome")
    end)
end)

Saving.SaveAdded:Connect(function(player)
    local save = Saving.Get(player)
    if save then
        if save.Joins == 1 then
            Network.Fire(player, "PromptFavorite", 1)
        end

        save.Joins += 1
    end

    task.spawn(function()
        while player.Parent do
            local save = Saving.Get(player)

            if save then
                save.Playtime += 1
            end

            task.wait(1)
        end
    end)
end)

Network.Fired("PromptedNotifications", function(player)
    local save = Saving.Get(player)
    if save then
        save.PromptedNotifications = true
    end
end)