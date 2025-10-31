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
local Saving = require(ServerScriptService.Library.Saving)
local Players = game:GetService("Players")

local TOPIC = "SleepyFish:AdminGlobalMessage"
local FORCE_RARITY_TOPIC = "SleepyFish:ForceRarity"
local GLOBAL_FORCE_GIVE_TOPIC = "SleepyFish:GlobalForceGive"
local GLOBAL_SLEEP_TOPIC = "SleepyFish:GlobalSleep"
local GLOBAL_FORCE_SPAWN_TOPIC = "SleepyFish:GlobalForceSpawn"
local GLOBAL_SKIP_CRAFTING_TOPIC = "SleepyFish:GlobalSkipCraftingTimes"
local GLOBAL_GIVE_SPINS_TOPIC = "SleepyFish:GlobalGiveSpins"

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
	local mutation = data.mutation
	local traits = data.traits
	
	if typeof(rarityId) ~= "string" then return end
	
	-- Validate mutation if provided by checking if it exists in the Mutations directory
	if mutation and not Directory.Mutations[mutation] then
		mutation = nil
	end
	
    pcall(function()
        FishGenerator.ForceSpawnRandomType(rarityId, nil, fishType, mutation, traits)
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
	local traits = data.traits
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
				Traits = traits,
				Shiny = false,
				Level = level
			})
			
			if fishData then
				ExistCount.IncrementCount(fishData.FishId, fishData.Type)
				if fishData.Mutation then
					ExistCount.IncrementMutationCount(fishData.FishId, fishData.Mutation)
				end
				Index.Add(player, fishData.FishId, fishData.Type, fishData.Mutation)
			end
		end)
	end

	local schema = Directory.Fish[fishId]
	if schema then
		local rarity = schema.Rarity
		local displayName = schema.DisplayName or fishId
		local typeText = (fishType ~= "Normal") and (fishType .. " ") or ""

		if rarity._id == "Mythical" then
			Notifications.MessageAll(`An Admin gave you a Mythical {typeText}{displayName}!`, {
				Rainbow = true,
				Time = 8,
			})
		elseif rarity._id == "God" then
			Notifications.MessageAll(`An Admin gave you a GOD {typeText}{displayName}!`, {
				Rainbow = true,
				Time = 8,
			})
		elseif rarity._id == "Secret" then
			Notifications.MessageAll(`An Admin gave you a SECRET {typeText}{displayName}!`, {
				Rainbow = true,
				Time = 8,
			})
		else
			Notifications.MessageAll(`An Admin gave you a {rarity.DisplayName} {typeText}{displayName}!`, {
				Time = 8,
			})
		end
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
	local traits = data.traits
	
	if typeof(fishId) ~= "string" then return end
	
	-- Validate mutation if provided by checking if it exists in the Mutations directory
	if mutation and not Directory.Mutations[mutation] then
		mutation = nil
	end
	
	-- Force spawn the specific fish in the ocean (admin-originated)
	pcall(function()
		FishGenerator.ForceSpawnSpecificFish(fishId, fishType, mutation, true, traits)
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

local function handleGlobalSkipCraftingTimes(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	
	local currentTime = workspace:GetServerTimeNow()
	local totalSkipped = 0
	local playersAffected = 0
	
	-- Loop through all players
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		local saveData = Saving.Get(targetPlayer)
		if saveData then
			local playerSkipped = 0
			
			-- Loop through all crafting machines and recipes
			for machineId, machineSlots in pairs(saveData.CraftingMachines) do
				for recipeKey, slot in pairs(machineSlots) do
					if slot and slot.CompletionTime then
						-- Set completion time to now
						slot.CompletionTime = currentTime
						playerSkipped = playerSkipped + 1
					end
				end
			end
			
			if playerSkipped > 0 then
				totalSkipped = totalSkipped + playerSkipped
				playersAffected = playersAffected + 1
			end
		end
	end
	
	if totalSkipped > 0 then
		print(`[GlobalSkipCraftingTimes] Skipped {totalSkipped} crafting timer(s) for {playersAffected} player(s)`)
	end

	-- Notify all players
	Notifications.MessageAll("Admin instantly finished all crafting times!", {
		Rainbow = true,
		Time = 8,
	})
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(GLOBAL_SKIP_CRAFTING_TOPIC, handleGlobalSkipCraftingTimes)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)

local function handleGlobalGiveSpins(message: Message)
	local data = message and (message :: any).Data
	if typeof(data) ~= "table" then return end
	local wheelId = data.wheelId
	local amount = data.amount
	local spinType = data.spinType or "Free"
	
	if typeof(wheelId) ~= "string" then return end
	if typeof(amount) ~= "number" or amount <= 0 then return end
	
	local SpinnyWheelDirectory = require(ReplicatedStorage.Game.Library.Directory.SpinnyWheels)
	
	-- Validate wheel exists
	local wheelSchema = SpinnyWheelDirectory[wheelId]
	if not wheelSchema then return end
	
	local wheelDisplayName = wheelSchema.DisplayName or wheelId
	local totalGiven = 0
	
	-- Give spins to all online players
	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			local saveData = Saving.Get(player)
			if saveData then
				-- Initialize wheels table if needed
				saveData.Wheels = saveData.Wheels or {}
				saveData.Wheels[wheelId] = saveData.Wheels[wheelId] or { Free = 0, Paid = 0, FreeNextAt = nil }
				
				-- Add spins
				if spinType == "Free" then
					saveData.Wheels[wheelId].Free = (saveData.Wheels[wheelId].Free or 0) + amount
				else
					saveData.Wheels[wheelId].Paid = (saveData.Wheels[wheelId].Paid or 0) + amount
				end
				
				totalGiven = totalGiven + 1
			end
		end)
	end
	
	if totalGiven > 0 then
		print(`[GlobalGiveSpins] Gave {amount} {spinType} spins for wheel "{wheelId}" to {totalGiven} player(s)`)
	end
	
	-- Notify all players with rainbow text
	Notifications.MessageAll(`Admin gave you {amount} {wheelDisplayName} spins!`, {
		Rainbow = true,
		Time = 7,
	})
end

task.spawn(function()
	while true do
		local ok, subOrErr = pcall(function()
			return MessagingService:SubscribeAsync(GLOBAL_GIVE_SPINS_TOPIC, handleGlobalGiveSpins)
		end)
		if ok and subOrErr then
			break
		end
		task.wait(5)
	end
end)


