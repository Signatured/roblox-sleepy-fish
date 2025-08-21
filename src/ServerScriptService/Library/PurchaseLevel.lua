--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
local Network = require(game.ServerScriptService.Library.Network)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)

local module = {}

type PendingLevelUp = {
	PlotId: number,
	Index: number,
	UID: string,
}

local waitingPurchase: {[Player]: PendingLevelUp} = {}

local function findFish(plot: any, index: number)
	if not plot then return nil end
	local fishes = plot:Save("Fish")
	if typeof(fishes) ~= "table" then return nil end
	local key = tostring(index)
	return fishes[key]
end

-- Client requests to level up a fish: (plotId, fishIndex, fishUID)
Network.Fired("LevelUp", function(player: Player, plotId: number, index: number, fishUID: string)
	if typeof(plotId) ~= "number" or typeof(index) ~= "number" or typeof(fishUID) ~= "string" then return end
	local plot = ServerPlot.GetById(plotId)
	if not plot then return end
	local fish = findFish(plot, index)
	if not fish or typeof(fish) ~= "table" or typeof(fish.UID) ~= "string" or fish.UID ~= fishUID then return end

	waitingPurchase[player] = {
		PlotId = plotId,
		Index = index,
		UID = fish.UID,
	}

	local product = Products["Skip Level"]
	if product and typeof(product.ProductId) == "number" then
		Marketplace.Prompt(player, product.ProductId, true)
	else
		warn("[PurchaseLevel] Product 'Skip Level' not found or invalid ProductId")
	end
end)

function module.ExecuteLevelUp(player: Player): boolean
	local pending = waitingPurchase[player]
	if not pending then
		return false
	end

	local plot = ServerPlot.GetById(pending.PlotId)
	if not plot then
		waitingPurchase[player] = nil
		return false
	end

	local fish = findFish(plot, pending.Index)
	if not fish or typeof(fish.UID) ~= "string" then
		waitingPurchase[player] = nil
		return false
	end

	if fish.UID ~= pending.UID then
		waitingPurchase[player] = nil
		return false
	end

	-- Level up and write back to plot
	local currentLevel = (fish.FishData and fish.FishData.Level) or 0
	if not fish.FishData then fish.FishData = {} end
	fish.FishData.Level = currentLevel + 1
	plot:SetFish(fish, pending.Index)

	waitingPurchase[player] = nil
	return true
end

-- Cleanup waiting purchase when player leaves
Players.PlayerRemoving:Connect(function(player)
	waitingPurchase[player] = nil
end)

return module


