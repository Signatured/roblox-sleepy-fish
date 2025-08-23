--!strict

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local BadgeManager = {}

-- Simple in-memory cache to reduce repeat checks during a session
-- {[userId]: {[badgeId]: boolean}}
local hasBadgeCache: {[number]: {[number]: boolean}} = {}

local badgeIds = {
    ["Welcome"] = 4219049404355064,
    ["NewCoil"] = 3530277192427927,
    ["FirstCatch"] = 2863084365172080,
    ["NewStand"] = 1963645112837265,
    ["TheLegend"] = 2611268647815735,
    ["First1k"] = 3500787017067735,
    ["First100k"] = 1194718105387670,
    ["First1m"] = 2112559936842046,
}

local function userHasBadge(userId: number, badgeId: number): boolean
    local userCache = hasBadgeCache[userId]
    if userCache and userCache[badgeId] ~= nil then
        return userCache[badgeId]
    end

    local ok, result = pcall(BadgeService.UserHasBadgeAsync, BadgeService, userId, badgeId)
    local hasIt = ok and result == true

    if not hasBadgeCache[userId] then
        hasBadgeCache[userId] = {}
    end
    hasBadgeCache[userId][badgeId] = hasIt

    return hasIt
end

local function setHasBadge(userId: number, badgeId: number, value: boolean)
    if not hasBadgeCache[userId] then
        hasBadgeCache[userId] = {}
    end
    hasBadgeCache[userId][badgeId] = value
end

function BadgeManager.GiveMoneyBadge(player: Player, money: number): boolean
    if money >= 1_000 then
        return BadgeManager.GiveBadgeByName(player, "First1k")
    end
    if money >= 100_000 then
        return BadgeManager.GiveBadgeByName(player, "First100k")
    end
    if money >= 1_000_000 then
        return BadgeManager.GiveBadgeByName(player, "First1m")
    end

    return false
end

function BadgeManager.GiveBadgeByName(player: Player, badgeName: string): boolean
    local badgeId = badgeIds[badgeName]
    if not badgeId then
        warn(string.format("[BadgeManager] Badge %s not found", badgeName))
        return false
    end
    return BadgeManager.GiveBadge(player, badgeId)
end

-- Gives a badge to the player if they don't already have it.
-- Returns true if the player owns (or now owns) the badge, false otherwise.
function BadgeManager.GiveBadge(player: Player, badgeId: number): boolean
    if not player or typeof(badgeId) ~= "number" then
        return false
    end

    local userId = player.UserId

    -- Skip if we already know they have it
    if userHasBadge(userId, badgeId) then
        return true
    end

    -- Attempt to award the badge
    local ok, err = pcall(BadgeService.AwardBadge, BadgeService, userId, badgeId)
    if not ok then
        warn(string.format("[BadgeManager] Failed to award badge %d to %s: %s", badgeId, player.Name, tostring(err)))
        return false
    end

    -- Update cache optimistically; service will ignore duplicates anyway
    setHasBadge(userId, badgeId, true)
    return true
end

-- Cleanup cache on player leaving to avoid unbounded growth
Players.PlayerRemoving:Connect(function(player: Player)
    hasBadgeCache[player.UserId] = nil
end)

return BadgeManager


