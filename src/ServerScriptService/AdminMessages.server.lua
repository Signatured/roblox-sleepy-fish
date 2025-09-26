--!strict

-- Server relay for global admin messages via MessagingService

local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)
local Fish = require(ServerScriptService.Game.Library.Fish)
local ExistCount = require(ServerScriptService.Game.Library.ExistCount)
local Index = require(ServerScriptService.Game.Library.Index)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local Enemies = require(ServerScriptService.Game.Library.Enemies)
local Notifications = require(ServerScriptService.Library.Notifications)
local Players = game:GetService("Players")

local TOPIC = "SleepyFish:AdminGlobalMessage"
local FORCE_RARITY_TOPIC = "SleepyFish:ForceRarity"
local GLOBAL_FORCE_GIVE_TOPIC = "SleepyFish:GlobalForceGive"
local GLOBAL_SLEEP_TOPIC = "SleepyFish:GlobalSleep"
local GLOBAL_FORCE_SPAWN_TOPIC = "SleepyFish:GlobalForceSpawn"

local function handleIncomingMessage(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	local userId = data.userId
	local text = data.text
	if typeof(userId) ~= "number" then return end
	if typeof(text) ~= "string" then return end

	Network.FireAll("Admin Global Message", userId, text)
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(TOPIC, handleIncomingMessage)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)

local function handleForceRarity(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	local rarityId = data.rarityId
    local fishType = data.fishType
	if typeof(rarityId) ~= "string" then return end
    pcall(function()
        FishGenerator.ForceSpawnRandomType(rarityId, nil, fishType)
    end)
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(FORCE_RARITY_TOPIC, handleForceRarity)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)

local function handleGlobalForceGive(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	local fishId = data.fishId
	local fishType = data.fishType or "Normal"
	local mutation = data.mutation
	local level = data.level or 1
	
	if typeof(fishId) ~= "string" then return end
	
	-- Validate mutation if provided by checking if it exists in the Mutations directory
	if mutation and not Directory.Mutations[mutation] then
		mutation = nil
	end
	
	-- Give fish to all online players
	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			local fishData = Fish.Give(player, {
				FishId = fishId,
				Type = fishType,
				Mutation = mutation,
				Shiny = false,
				Level = level
			})
			
			if fishData then
				ExistCount.IncrementCount(fishData.FishId, fishData.Type)
				if fishData.Mutation == "Bloodfish" then
					ExistCount.IncrementBloodfishCount(fishData.FishId)
				end
				Index.Add(player, fishData.FishId, fishData.Type, fishData.Mutation)
			end
		end)
	end
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(GLOBAL_FORCE_GIVE_TOPIC, handleGlobalForceGive)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)

local function handleGlobalSleep(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	local duration = data.duration
	
	if typeof(duration) ~= "number" or duration <= 0 then
		duration = 60
	end
	
	-- Sleep all fish for the specified duration
	pcall(function()
		Enemies.SleepAll(duration)

		Notifications.MessageAll(`All fish are sleeping for {duration} seconds!`, {
			Rainbow = true,
			Time = 8
		})
	end)
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(GLOBAL_SLEEP_TOPIC, handleGlobalSleep)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)

local function handleGlobalForceSpawn(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	local fishId = data.fishId
	local fishType = data.fishType or "Normal"
	local mutation = data.mutation
	
	if typeof(fishId) ~= "string" then return end
	
	-- Validate mutation if provided by checking if it exists in the Mutations directory
	if mutation and not Directory.Mutations[mutation] then
		mutation = nil
	end
	
	-- Force spawn the specific fish in the ocean (admin-originated)
	pcall(function()
		FishGenerator.ForceSpawnSpecificFish(fishId, fishType, mutation, true)
	end)
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(GLOBAL_FORCE_SPAWN_TOPIC, handleGlobalForceSpawn)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)


