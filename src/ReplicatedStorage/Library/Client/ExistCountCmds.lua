--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)

export type CountsByType = {
    Normal: number,
    Shiny: number,
    Gold: number,
    Rainbow: number,
    Bloodfish: number,
    Galaxy: number,
}

local ExistCountCmds = {}

local cache: {[string]: CountsByType} = {}

function ExistCountCmds.GetAll(): {[string]: CountsByType}
    return cache
end

function ExistCountCmds.GetById(fishId: string): CountsByType?
    return cache[fishId]
end

function ExistCountCmds.GetByIdAndType(fishId: string, fishType: string): number
    local localVal = cache[fishId]
    if not localVal then return 0 end
    if fishType == "Normal" then return localVal.Normal
    elseif fishType == "Shiny" then return localVal.Shiny
    elseif fishType == "Gold" then return localVal.Gold
    elseif fishType == "Rainbow" then return localVal.Rainbow
    elseif fishType == "Bloodfish" then return localVal.Bloodfish
    elseif fishType == "Galaxy" then return localVal.Galaxy
    end
    return 0
end

function ExistCountCmds.GetBloodfishCount(fishId: string): number
    local localVal = cache[fishId]
    if not localVal then return 0 end
    return localVal.Bloodfish or 0
end

function ExistCountCmds.GetGalaxyCount(fishId: string): number
    local localVal = cache[fishId]
    if not localVal then return 0 end
    return localVal.Galaxy or 0
end

-- initial fetch
task.spawn(function()
    local data = Network.Invoke("ExistCount_GetAll")
    if typeof(data) == "table" then
        cache = data
    end
end)

-- server push updates
Network.Fired("ExistCount_Update", function(data)
    if typeof(data) == "table" then
        cache = data
    end
end)

return ExistCountCmds


