--!strict

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local Saving = require(game.ServerScriptService.Library.Saving)
local BadgeManager = require(game.ServerScriptService.Game.Library.BadgeManager)
local Network = require(game.ServerScriptService.Library.Network)
local Gadgets = require(game.ServerScriptService.Game.Library.Gadgets)

local function setCharacterCollisionGroup(character: Model)
    for _, inst in ipairs(character:GetDescendants()) do
        if inst:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(inst, "Player")
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
        -- Give any owned gadgets from the player's save once their Backpack exists
        task.spawn(function()
            local backpack = player:FindFirstChildOfClass("Backpack")
            if not backpack then
                player.CharacterAdded:Wait()
                backpack = player:FindFirstChildOfClass("Backpack")
            end
            if backpack and save.Tools then
                for id, owned in pairs(save.Tools) do
                    if owned then
                        Gadgets.Give(player, id)
                    end
                end
            end
        end)
        
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