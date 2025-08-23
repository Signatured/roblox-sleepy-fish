--!strict

-- Periodically checks whether players have completed the entire fish index
-- (all fish types and all variants). If so, awards the "TheLegend" badge.

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local Index = require(game.ServerScriptService.Game.Library.Index)

local LEGEND_BADGE_ID = 2611268647815735

local function _isIndexEntryComplete(entry: any): boolean
    if type(entry) ~= "table" then return false end
    -- All four variants must be true
    return (entry.Normal == true) and (entry.Shiny == true) and (entry.Gold == true) and (entry.Rainbow == true)
end

local function isPlayerIndexComplete(player: Player): boolean
    return Index.IsCompleted(player)
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


