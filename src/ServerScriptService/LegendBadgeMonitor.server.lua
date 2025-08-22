--!strict

-- Periodically checks whether players have completed the entire fish index
-- (all fish types and all variants). If so, awards the "TheLegend" badge.

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local Directory = require(game.ReplicatedStorage.Game.Library.Directory)
local Saving = require(game.ServerScriptService.Library.Saving)

local LEGEND_BADGE_ID = 2611268647815735

local function isIndexEntryComplete(entry: any): boolean
    if type(entry) ~= "table" then return false end
    -- All four variants must be true
    return (entry.Normal == true) and (entry.Shiny == true) and (entry.Gold == true) and (entry.Rainbow == true)
end

local function isPlayerIndexComplete(player: Player): boolean
    local save = Saving.Get(player)
    if not save then return false end

    local indexMap = save.Index :: {[string]: any}
    if type(indexMap) ~= "table" then return false end

    for fishId, _dir in pairs(Directory.Fish) do
        local entry = indexMap[fishId]
        if not isIndexEntryComplete(entry) then
            return false
        end
    end
    return true
end

local function startMonitoringPlayer(player: Player)
    task.spawn(function()
        while player.Parent do
            -- Only run once per second
            task.wait(1)

            if isPlayerIndexComplete(player) then
                local okHas, hasIt = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, LEGEND_BADGE_ID)
                if okHas and hasIt then
                    break
                end
                pcall(BadgeService.AwardBadge, BadgeService, player.UserId, LEGEND_BADGE_ID)
                break
            end
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    startMonitoringPlayer(p)
end

Players.PlayerAdded:Connect(startMonitoringPlayer)


