--!strict

local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local _RunService = game:GetService("RunService")

local Network = require(ServerScriptService.Library.Network)
local _Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)

export type CountsByType = {
    Normal: number,
    Shiny: number,
    Gold: number,
    Rainbow: number,
    Bloodfish: number,
}

local ExistCount = {}

local DATASTORE_KEY = "ExistCountV4"
local lastPersisted: {[string]: CountsByType} = {}
local cache: {[string]: CountsByType} = {}

local function emptyCounts(): CountsByType
    return { Normal = 0, Shiny = 0, Gold = 0, Rainbow = 0, Bloodfish = 0 }
end

local function deepCopyCounts(src: {[string]: CountsByType}): {[string]: CountsByType}
    local dest: {[string]: CountsByType} = {}
    for k, v in pairs(src) do
        dest[k] = { Normal = v.Normal or 0, Shiny = v.Shiny or 0, Gold = v.Gold or 0, Rainbow = v.Rainbow or 0, Bloodfish = v.Bloodfish or 0 }
    end
    return dest
end

local function _addCounts(a: CountsByType, b: CountsByType)
    a.Normal += b.Normal or 0
    a.Shiny += b.Shiny or 0
    a.Gold += b.Gold or 0
    a.Rainbow += b.Rainbow or 0
    a.Bloodfish += b.Bloodfish or 0
end

local function readFromDataStore(): {[string]: CountsByType}
    local DataStoreService = game:GetService("DataStoreService")
    local ds = DataStoreService:GetDataStore("GlobalExistCount")
    local ok, data = pcall(function()
        return ds:GetAsync(DATASTORE_KEY)
    end)
    if ok and type(data) == "table" then
        local normalized: {[string]: CountsByType} = {}
        for fishId, counts in pairs(data) do
            if type(counts) == "table" then
                local c: CountsByType = emptyCounts()
                c.Normal = tonumber((counts :: any).Normal) or 0
                c.Shiny = tonumber((counts :: any).Shiny) or 0
                c.Gold = tonumber((counts :: any).Gold) or 0
                c.Rainbow = tonumber((counts :: any).Rainbow) or 0
                c.Bloodfish = tonumber((counts :: any).Bloodfish) or 0
                normalized[fishId] = c
            end
        end
        return normalized
    end
    return {}
end

-- No direct SetAsync writes; we will use UpdateAsync to merge deltas atomically

local function getDeltas(): {[string]: CountsByType}
    local deltas: {[string]: CountsByType} = {}
    for fishId, nowCounts in pairs(cache) do
        local prev = lastPersisted[fishId] or emptyCounts()
        local d: CountsByType = { Normal = 0, Shiny = 0, Gold = 0, Rainbow = 0, Bloodfish = 0 }
        d.Normal = (nowCounts.Normal or 0) - (prev.Normal or 0)
        d.Shiny = (nowCounts.Shiny or 0) - (prev.Shiny or 0)
        d.Gold = (nowCounts.Gold or 0) - (prev.Gold or 0)
        d.Rainbow = (nowCounts.Rainbow or 0) - (prev.Rainbow or 0)
        d.Bloodfish = (nowCounts.Bloodfish or 0) - (prev.Bloodfish or 0)
        if d.Normal ~= 0 or d.Shiny ~= 0 or d.Gold ~= 0 or d.Rainbow ~= 0 or d.Bloodfish ~= 0 then
            deltas[fishId] = d
        end
    end
    return deltas
end

local function refreshCacheFromStoreOnce()
    local storeData = readFromDataStore()
    
    -- Calculate any pending increments before refresh
    local pendingDeltas = getDeltas()
    
    -- Update cache with store data
    cache = deepCopyCounts(storeData)
    lastPersisted = deepCopyCounts(storeData)
    
    -- Re-apply any pending increments that weren't persisted
    for fishId, delta in pairs(pendingDeltas) do
        local counts = cache[fishId] or emptyCounts()
        counts.Normal = math.max(0, counts.Normal + delta.Normal)
        counts.Shiny = math.max(0, counts.Shiny + delta.Shiny)
        counts.Gold = math.max(0, counts.Gold + delta.Gold)
        counts.Rainbow = math.max(0, counts.Rainbow + delta.Rainbow)
        counts.Bloodfish = math.max(0, counts.Bloodfish + delta.Bloodfish)
        cache[fishId] = counts
    end
end

local persisting = false
local function persistDeltas()
    if persisting then return end
    local deltas = getDeltas()
    local hasDelta = false
    for _, d in pairs(deltas) do
        if (d.Normal or 0) ~= 0 or (d.Shiny or 0) ~= 0 or (d.Gold or 0) ~= 0 or (d.Rainbow or 0) ~= 0 or (d.Bloodfish or 0) ~= 0 then
            hasDelta = true
            break
        end
    end
    if not hasDelta then return end
    
    persisting = true
    local DataStoreService = game:GetService("DataStoreService")
    local ds = DataStoreService:GetDataStore("GlobalExistCount")

    local ok, result = pcall(function()
        return ds:UpdateAsync(DATASTORE_KEY, function(old)
            local current: {[string]: CountsByType}
            if type(old) == "table" then
                -- normalize existing table
                current = {}
                for fishId, counts in pairs(old) do
                    if type(counts) == "table" then
                        current[fishId] = {
                            Normal = tonumber((counts :: any).Normal) or 0,
                            Shiny = tonumber((counts :: any).Shiny) or 0,
                            Gold = tonumber((counts :: any).Gold) or 0,
                            Rainbow = tonumber((counts :: any).Rainbow) or 0,
                            Bloodfish = tonumber((counts :: any).Bloodfish) or 0,
                        }
                    end
                end
            else
                current = {}
            end

            -- apply our deltas, clamped to >= 0
            for fishId, d in pairs(deltas) do
                local base = current[fishId] or emptyCounts()
                base.Normal = math.max(0, (base.Normal or 0) + (d.Normal or 0))
                base.Shiny = math.max(0, (base.Shiny or 0) + (d.Shiny or 0))
                base.Gold = math.max(0, (base.Gold or 0) + (d.Gold or 0))
                base.Rainbow = math.max(0, (base.Rainbow or 0) + (d.Rainbow or 0))
                base.Bloodfish = math.max(0, (base.Bloodfish or 0) + (d.Bloodfish or 0))
                current[fishId] = base
            end
            return current
        end)
    end)

    -- Always reset persisting flag, even on error
    persisting = false
    
    if ok and type(result) == "table" then
        -- Only update lastPersisted if the operation succeeded
        lastPersisted = deepCopyCounts(result)
        local deltaCount = 0
        for _ in pairs(deltas) do deltaCount += 1 end
        print("[ExistCount] Successfully persisted deltas for", deltaCount, "fish types")
    else
        warn("[ExistCount] Failed to persist deltas:", result)
        -- On failure, we keep the deltas in cache and will try again next time
    end
end

local function getRandomInterval(): number
    return math.random(15, 30) * 60
end

-- Public API
function ExistCount.IncrementCount(fishId: string, fishType: FishTypes.fish_type)
    local counts = cache[fishId]
    if not counts then counts = emptyCounts(); cache[fishId] = counts end
    
    -- Increment and ensure non-negative values
    if fishType == "Normal" then 
        counts.Normal = math.max(0, counts.Normal + 1)
    elseif fishType == "Shiny" then 
        counts.Shiny = math.max(0, counts.Shiny + 1)
    elseif fishType == "Gold" then 
        counts.Gold = math.max(0, counts.Gold + 1)
    elseif fishType == "Rainbow" then 
        counts.Rainbow = math.max(0, counts.Rainbow + 1)
    end
end

function ExistCount.IncrementBloodfishCount(fishId: string)
    local counts = cache[fishId]
    if not counts then counts = emptyCounts(); cache[fishId] = counts end
    
    counts.Bloodfish = math.max(0, counts.Bloodfish + 1)
end

function ExistCount.GetAll(): {[string]: CountsByType}
    return deepCopyCounts(cache)
end

function ExistCount.GetById(fishId: string): CountsByType
    local c = cache[fishId]
    if not c then return emptyCounts() end
    return { Normal = c.Normal or 0, Shiny = c.Shiny or 0, Gold = c.Gold or 0, Rainbow = c.Rainbow or 0, Bloodfish = c.Bloodfish or 0 }
end

function ExistCount.GetByIdAndType(fishId: string, fishType: FishTypes.fish_type): number
    local c = cache[fishId]
    if not c then return 0 end
    if fishType == "Normal" then return c.Normal or 0
    elseif fishType == "Shiny" then return c.Shiny or 0
    elseif fishType == "Gold" then return c.Gold or 0
    elseif fishType == "Rainbow" then return c.Rainbow or 0
    end
    return 0
end

function ExistCount.GetBloodfishCount(fishId: string): number
    local c = cache[fishId]
    if not c then return 0 end
    return c.Bloodfish or 0
end

-- Networking
Network.Invoked("ExistCount_GetAll", function(_player: Player)
    return ExistCount.GetAll()
end)

Network.Invoked("ExistCount_GetById", function(_player: Player, fishId: string)
    return ExistCount.GetById(fishId)
end)

Network.Invoked("ExistCount_GetByIdAndType", function(_player: Player, fishId: string, fishType: FishTypes.fish_type)
    return ExistCount.GetByIdAndType(fishId, fishType)
end)

Network.Invoked("ExistCount_GetBloodfishCount", function(_player: Player, fishId: string)
    return ExistCount.GetBloodfishCount(fishId)
end)

-- Periodic tasks: refresh cache from store and persist deltas
task.spawn(function()
    refreshCacheFromStoreOnce()
end)

-- Optionally broadcast a view of current server-side counts
task.spawn(function()
    while true do
        task.wait(getRandomInterval())
        Network.FireAll("ExistCount_Update", ExistCount.GetAll())
    end
end)

task.spawn(function()
    while true do
        task.wait(getRandomInterval())
        persistDeltas()
    end
end)

-- Periodically refresh cache from store to stay in sync with other servers
task.spawn(function()
    while true do
        task.wait(getRandomInterval() * 2) -- Less frequent than persist
        pcall(function()
            refreshCacheFromStoreOnce()
            print("[ExistCount] Refreshed cache from datastore")
        end)
    end
end)

-- On server shutdown, persist any remaining deltas once
game:BindToClose(function()
    -- best effort: write any outstanding deltas
    pcall(function()
        persistDeltas()
    end)
end)

return ExistCount


