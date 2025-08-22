--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
local Network = require(game.ServerScriptService.Library.Network)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)
local Fish = require(game.ServerScriptService.Game.Library.Fish)
local Index = require(game.ServerScriptService.Game.Library.Index)

local module = {}

type PendingSteal = {
    PlotId: number,
    Index: number,
    UID: string,
}

local waitingPurchase: {[Player]: PendingSteal} = {}

local function findFish(plot: any, index: number)
    if not plot then return nil end
    local fishes = plot:Save("Fish")
    if typeof(fishes) ~= "table" then return nil end
    local key = tostring(index)
    return fishes[key]
end

-- Client requests to steal a fish: (plotId, fishIndex)
Network.Fired("Steal", function(player: Player, plotId: number, index: number, fishUID: string)
    if typeof(plotId) ~= "number" or typeof(index) ~= "number" then return end
    local plot = ServerPlot.GetById(plotId)
    if not plot then return end
    local fish = findFish(plot, index)
    if not fish or typeof(fish) ~= "table" or typeof(fish.UID) ~= "string" or fish.UID ~= fishUID then return end

    waitingPurchase[player] = {
        PlotId = plotId,
        Index = index,
        UID = fish.UID,
    }

    local stealProduct = Products["Steal"]
    if stealProduct and typeof(stealProduct.ProductId) == "number" then
        Marketplace.Prompt(player, stealProduct.ProductId, true)
    else
        warn("[Steal] Product 'Steal' not found or invalid ProductId")
    end
end)

function module.ExecuteSteal(player: Player): boolean
    local pending = waitingPurchase[player]
    if not pending then
        return false
    end

    local plot = ServerPlot.GetById(pending.PlotId)
    if not plot then
        waitingPurchase[player] = nil
        return false
    end

    local currentFish = findFish(plot, pending.Index)
    if not currentFish or typeof(currentFish.UID) ~= "string" then
        waitingPurchase[player] = nil
        return false
    end

    if currentFish.UID ~= pending.UID then
        waitingPurchase[player] = nil
        return false
    end

    plot:DeleteFish(pending.Index)
    local data = Fish.Give(player, currentFish.FishData)
    if data then
        Fish.ForceHoldFish(player, data)
        Index.Add(player, data.FishId, data.Type)
    end

    waitingPurchase[player] = nil
    return true
end

-- Cleanup waiting purchase when player leaves
Players.PlayerRemoving:Connect(function(player)
    waitingPurchase[player] = nil
end)

return module