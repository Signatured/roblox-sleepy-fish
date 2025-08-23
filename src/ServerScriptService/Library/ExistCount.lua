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
}

local ExistCount = {}

local DATASTORE_KEY = "ExistCountV1"
local lastPersisted: {[string]: CountsByType} = {}
local cache: {[string]: CountsByType} = {}

local function emptyCounts(): CountsByType
    return { Normal = 0, Shiny = 0, Gold = 0, Rainbow = 0 }
end

local function deepCopyCounts(src: {[string]: CountsByType}): {[string]: CountsByType}
    local dest: {[string]: CountsByType} = {}
    for k, v in pairs(src) do
        dest[k] = { Normal = v.Normal or 0, Shiny = v.Shiny or 0, Gold = v.Gold or 0, Rainbow = v.Rainbow or 0 }
    end
    return dest
end

local function addCounts(a: CountsByType, b: CountsByType)
    a.Normal += b.Normal or 0
    a.Shiny += b.Shiny or 0
    a.Gold += b.Gold or 0
    a.Rainbow += b.Rainbow or 0
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
                normalized[fishId] = c
            end
        end
        return normalized
    end
    return {}
end

local function writeToDataStore(data: {[string]: CountsByType})
    local DataStoreService = game:GetService("DataStoreService")
    local ds = DataStoreService:GetDataStore("GlobalExistCount")
    pcall(function()
        ds:SetAsync(DATASTORE_KEY, data)
    end)
end

local function refreshCacheFromStore()
    local storeData = readFromDataStore()
    cache = deepCopyCounts(storeData)
    lastPersisted = deepCopyCounts(storeData)
end

local function getDeltas(): {[string]: CountsByType}
    local deltas: {[string]: CountsByType} = {}
    for fishId, nowCounts in pairs(cache) do
        local prev = lastPersisted[fishId] or emptyCounts()
        local d: CountsByType = { Normal = 0, Shiny = 0, Gold = 0, Rainbow = 0 }
        d.Normal = (nowCounts.Normal or 0) - (prev.Normal or 0)
        d.Shiny = (nowCounts.Shiny or 0) - (prev.Shiny or 0)
        d.Gold = (nowCounts.Gold or 0) - (prev.Gold or 0)
        d.Rainbow = (nowCounts.Rainbow or 0) - (prev.Rainbow or 0)
        if d.Normal ~= 0 or d.Shiny ~= 0 or d.Gold ~= 0 or d.Rainbow ~= 0 then
            deltas[fishId] = d
        end
    end
    return deltas
end

local function persistDeltas()
    local store = readFromDataStore()
    for fishId, delta in pairs(getDeltas()) do
        local base = store[fishId] or emptyCounts()
        addCounts(base, delta)
        store[fishId] = base
    end
    writeToDataStore(store)
    lastPersisted = deepCopyCounts(store)
end

local function getRandomInterval(): number
    return math.random(15, 30) * 60
end

-- Public API
function ExistCount.IncrementCount(fishId: string, fishType: FishTypes.fish_type)
    local counts = cache[fishId]
    if not counts then counts = emptyCounts(); cache[fishId] = counts end
    if fishType == "Normal" then counts.Normal += 1
    elseif fishType == "Shiny" then counts.Shiny += 1
    elseif fishType == "Gold" then counts.Gold += 1
    elseif fishType == "Rainbow" then counts.Rainbow += 1 end
end

function ExistCount.GetAll(): {[string]: CountsByType}
    return deepCopyCounts(cache)
end

function ExistCount.GetById(fishId: string): CountsByType
    local c = cache[fishId]
    if not c then return emptyCounts() end
    return { Normal = c.Normal or 0, Shiny = c.Shiny or 0, Gold = c.Gold or 0, Rainbow = c.Rainbow or 0 }
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

-- Periodic tasks: refresh cache from store and persist deltas
task.spawn(function()
    refreshCacheFromStore()
end)

task.spawn(function()
    while true do
        task.wait(getRandomInterval())
        refreshCacheFromStore()
        -- push update to clients
        Network.FireAll("ExistCount_Update", ExistCount.GetAll())
    end
end)

task.spawn(function()
    while true do
        task.wait(getRandomInterval())
        persistDeltas()
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


