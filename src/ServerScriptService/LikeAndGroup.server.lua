--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local Saving = require(ServerScriptService.Library.Saving)
local Notifications = require(ServerScriptService.Library.Notifications)
local Fish = require(ServerScriptService.Game.Library.Fish)
local ExistCount = require(ServerScriptService.Game.Library.ExistCount)
local Index = require(ServerScriptService.Game.Library.Index)

local GROUP_ID = 535442508

local function isInGroup(player: Player): boolean
    local ok, res = pcall(function()
        return player:IsInGroup(GROUP_ID)
    end)
    return ok and res == true
end

Network.Fired("LikeAndGroup_Claim", function(player: Player)
    if not isInGroup(player) then return end

    local save = Saving.Get(player)
    if not save then return end

    if save.GroupReward == true then return end

    save.GroupReward = true

    local data = Fish.Give(player, {
        FishId = "Bananita Dolphinita",
        Type = "Normal",
        Shiny = false,
        Level = 1,
    })

    if data then
        Fish.ForceHoldFish(player, data)
        ExistCount.IncrementCount(data.FishId, data.Type)
        Index.Add(player, data.FishId, data.Type)
    end

    Notifications.Message(player, "Thanks for playing! 💖")
end)


