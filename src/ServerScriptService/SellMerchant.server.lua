local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local ServerPlot = require(ServerScriptService.Plot.ServerPlot)
local Fish = require(ServerScriptService.Game.Library.Fish)
local Saving = require(ServerScriptService.Library.Saving)
local Gamepasses = require(ServerScriptService.Library.Gamepasses)
local GamepassDirectory = require(ReplicatedStorage.Game.Library.Directory.Gamepasses)

-- Resolve Double Money gamepass from directory rather than hardcoding ID
local DOUBLE_MONEY_SCHEMA = GamepassDirectory["Double Money"]

-- Compute sell price using the same logic as ServerPlot:GetSellPrice
local function computeSellPrice(plot: any, fishData: any): number?
	if not plot then return nil end
	-- Temporarily inject fishData into a faux index reader by FishId and Level
	-- We mirror the GetSellPrice math: ceil(GetMoneyPerSecond(index) * 20)
	-- Here we compute MPS from directory only (Exclusive filtered earlier)
	local dir = Directory.Fish[fishData.FishId]
	if not dir then return nil end
	local level = fishData.Level or 1
	local base = dir.MoneyPerSecond * level
	return math.ceil(base * 20)
end

-- Sell a list of inventory UIDs; returns total money added and list of sold UIDs
Network.Invoked("SellMerchant_Sell", function(player: Player, uids: {string})
	if type(uids) ~= "table" then return false, "Invalid list" end
	local save = Saving.Get(player)
	if not save then return false, "Not ready" end
	local plot = ServerPlot.GetByPlayer(player)
	if not plot then return false, "No plot" end

	local total = 0
	local ownsDouble = Gamepasses.Owns(player, (DOUBLE_MONEY_SCHEMA and DOUBLE_MONEY_SCHEMA.GamepassId) or "Double Money")
	local moneyMultiplier = ownsDouble and 2 or 1
	local sold: {string} = {}
	for _, uid in ipairs(uids) do
		if type(uid) ~= "string" or uid == "" then continue end
		local fishData = Fish.GetFromInventory(player, uid)
		if fishData then
			local dir = Directory.Fish[fishData.FishId]
			if dir and dir.Rarity and dir.Rarity._id == "Exclusive" then
				continue -- do not sell Exclusive rarity fish
			end
			local price = computeSellPrice(plot, fishData)
			if type(price) == "number" and price > 0 then
				Fish.Take(player, uid)
				total += price * moneyMultiplier
				table.insert(sold, uid)
			end
		end
	end

	if total > 0 then
		plot:AddMoney(total)
	end

	return true, { Total = total, Sold = sold }
end)
