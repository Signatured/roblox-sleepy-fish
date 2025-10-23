--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Player = require(ReplicatedStorage.Library.Player)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local _FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(ReplicatedStorage.Game.Library.Directory.Rarity)
local _Functions = require(ReplicatedStorage.Library.Functions)
local Network = require(ServerScriptService.Library.Network)
local Saving = require(ServerScriptService.Library.Saving)
local Fish = require(script.Parent.Fish)
local ServerPlot = require(ServerScriptService.Plot.ServerPlot)
local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)
local Notifications = require(ServerScriptService.Library.Notifications)
local Functions = require(ReplicatedStorage.Library.Functions)
local Audio = require(ReplicatedStorage.Library.Audio)

export type Quest = {
	Index: number,
	FishId: string,
	Amount: number,
	Rarity: string,
	Progress: number,
	ReadyToClaim: boolean,
	Completed: boolean,
}

local DailyQuests = {}

-- Compute day key for EST midnight
local function getDayKey(): number
	local utc = workspace:GetServerTimeNow()
	local est = utc - (5 * 3600)
	return math.floor(est / 86400)
end

local function getAllFishOfRarity(rarityEnum): {string}
	local list: {string} = {}
	for id, dir in pairs(Directory.Fish) do
		if dir.Rarity == rarityEnum then
			local weight = tonumber(dir.RarityWeight) or 1
			for _ = 1, weight do
				list[#list+1] = id
			end
		end
	end
	return list
end

local function chooseWeighted(rarityEnum): string
	local pool = getAllFishOfRarity(rarityEnum)
	if #pool == 0 then return next(Directory.Fish) :: string end
	return pool[math.random(1, #pool)]
end

local function getRarityName(fishId: string): string
	local dir = Directory.Fish[fishId]
	-- Convert rarity enum-like value to a string tag
	for name, value in pairs(Directory.Rarity) do
		if value == dir.Rarity then
			return tostring(name)
		end
	end
	return "Unknown"
end

local function buildQuests(): {Quest}
	local q1Fish = (math.random() < 0.5) and chooseWeighted(Rarity.Common) or chooseWeighted(Rarity.Uncommon)
	local q1Amt = Directory.Fish[q1Fish].Rarity == Rarity.Common and 4 or 2
	local q1Rarity = getRarityName(q1Fish)

	local q2Fish = (math.random() < 0.5) and chooseWeighted(Rarity.Rare) or chooseWeighted(Rarity.Epic)
	local q2Amt = Directory.Fish[q2Fish].Rarity == Rarity.Rare and 3 or 2
	local q2Rarity = getRarityName(q2Fish)

	local q3Fish = (math.random() < 0.5) and chooseWeighted(Rarity.Epic) or chooseWeighted(Rarity.Legendary)
	local q3Amt = Directory.Fish[q3Fish].Rarity == Rarity.Epic and 2 or 1
	local q3Rarity = getRarityName(q3Fish)

	local quests: {Quest} = {
		{ Index = 1, FishId = q1Fish, Amount = q1Amt, Rarity = q1Rarity, Progress = 0, ReadyToClaim = false, Completed = false },
		{ Index = 2, FishId = q2Fish, Amount = q2Amt, Rarity = q2Rarity, Progress = 0, ReadyToClaim = false, Completed = false },
		{ Index = 3, FishId = q3Fish, Amount = q3Amt, Rarity = q3Rarity, Progress = 0, ReadyToClaim = false, Completed = false },
	}
	return quests
end

local function ensureQuestsFor(player: Player)
	local save = Saving.Get(player)
	if not save then return end
	save.HalloweenDailyQuests = save.HalloweenDailyQuests or { DayKey = nil, Current = nil, Quests = nil }
	local dq = save.HalloweenDailyQuests
	local today = getDayKey()
	if dq.DayKey ~= today or typeof(dq.Quests) ~= "table" then
		dq.DayKey = today
		dq.Current = 1
		dq.Quests = buildQuests()
	else
		if typeof(dq.Current) ~= "number" or (dq.Current :: number) < 1 then dq.Current = 1 end
	end
end

local function computeSellPrice(fishId: string): number
	local schema = Directory.Fish[fishId]
	local mps = (schema and tonumber(schema.MoneyPerSecond)) or 0
	return math.floor(mps * 20 * 25)
end

local function tryRemoveOneFish(player: Player, fishId: string): boolean
	local save = Saving.Get(player)
	if not save then return false end
	local inv = save.Inventory
	for i = #inv, 1, -1 do
		local f = inv[i]
		if f and f.FishId == fishId then
			Fish.Take(player, f.UID)
			return true
		end
	end
	return false
end

local function grantMoney(player: Player, amount: number)
    local plot = ServerPlot.GetByPlayer(player)
    if not plot then return end
    plot:AddMoney(amount)
end

local function syncClient(player: Player)
	local save = Saving.Get(player)
	if not save then return end
	Network.Fire(player, "HalloweenDailyQuests_Sync", save.HalloweenDailyQuests)
end

Network.Fired("HalloweenDailyQuests_Sell", function(player: Player)
	ensureQuestsFor(player)
	local save = Saving.Get(player)
	if not save then return end
	local dq = save.HalloweenDailyQuests
	local current = dq.Current :: number
	if current == nil then return end
	local quest = dq.Quests and dq.Quests[current]
	if not quest or quest.Completed or quest.ReadyToClaim then return end

	if tryRemoveOneFish(player, quest.FishId) then
        local dir = Directory.Fish[quest.FishId]
		quest.Progress += 1
		grantMoney(player, computeSellPrice(quest.FishId))
		if quest.Progress >= quest.Amount then
			quest.ReadyToClaim = true
		end
		syncClient(player)

        Notifications.Message(player, `You sold a {dir.DisplayName} for ${Functions.NumberShorten(computeSellPrice(quest.FishId))}!`)

        local pos = Player.Optional.Position(player)
        if pos then
            Audio.Play("rbxassetid://133458542234750", pos, 1, 0.3, nil, nil, nil, player)
        end
	end
end)

Network.Fired("HalloweenDailyQuests_Claim", function(player: Player)
	ensureQuestsFor(player)
	local save = Saving.Get(player)
	if not save then return end
	local dq = save.HalloweenDailyQuests
	local current = dq.Current :: number
	if current == nil then return end
	local quest = dq.Quests and dq.Quests[current]
	if not quest or not quest.ReadyToClaim or quest.Completed then return end

	quest.Completed = true
	quest.ReadyToClaim = false

    if current == 1 then
        grantMoney(player, 10_000)

        Notifications.Message(player, `Quest Completed!`, {
            Color = Color3.fromRGB(0, 255, 0),
        })
        Notifications.Message(player, `You earned ${Functions.NumberShorten(10_000)}!`, {
            Color = Color3.fromRGB(0, 255, 0),
        })
    elseif current == 2 then
        local plot = ServerPlot.GetByPlayer(player)
        if plot then
            plot:SessionSet("HalloweenDailyQuests_Multiplied", workspace:GetServerTimeNow() + (60 * 60 * 2))

            Notifications.Message(player, `Quest Completed!`, {
                Color = Color3.fromRGB(0, 255, 0),
            })
            Notifications.Message(player, `Enjoy 2x money for the next 2 hours! Must stay online!`, {
                Color = Color3.fromRGB(0, 255, 0),
            })
        end
    elseif current == 3 then
        Notifications.Message(player, `Quest Completed!`, {
            Color = Color3.fromRGB(0, 255, 0),
        })

        FishGenerator.ForceSpawnRandomType("Mythical", player)
    end

    local pos = Player.Optional.Position(player)
    if pos then
        Audio.Play("rbxassetid://110426600162491", pos, 1, 1, nil, nil, nil, player)
    end

	if current < 3 then
		dq.Current = current + 1
	else
		dq.Current = 3
	end
	syncClient(player)
end)

Saving.SaveAdded:Connect(function(player: Player)
	ensureQuestsFor(player)
	syncClient(player)
end)

local lastDayKey = nil
spawn(function()
	while true do
		task.wait(30)
		local today = getDayKey()
		if lastDayKey == nil then
			lastDayKey = today
		elseif today ~= lastDayKey then
			lastDayKey = today
			for _, player in ipairs(Players:GetPlayers()) do
				ensureQuestsFor(player)
				syncClient(player)
			end
		end
	end
end)

return DailyQuests
