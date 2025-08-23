--!strict

local Players = game:GetService("Players")

local Saving = require(game.ServerScriptService.Library.Saving)
local BadgeManager = require(game.ServerScriptService.Game.Library.BadgeManager)
local Network = require(game.ServerScriptService.Library.Network)

local function setCharacterCollisionGroup(character: Model)
    for _, inst in ipairs(character:GetDescendants()) do
        if inst:IsA("BasePart") then
            (inst :: BasePart).CollisionGroup = "Player"
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    -- Ensure this player is in the Player collision group on spawn and on respawn
    local function onCharAdded(char: Model)
        setCharacterCollisionGroup(char)
    end
    if player.Character then
        onCharAdded(player.Character :: Model)
    end
    player.CharacterAdded:Connect(onCharAdded)
    task.spawn(function()
        BadgeManager.GiveBadgeByName(player, "Welcome")
    end)
end)

Saving.SaveAdded:Connect(function(player)
    local save = Saving.Get(player)
    if save then
        save.Settings.Music = true
        
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