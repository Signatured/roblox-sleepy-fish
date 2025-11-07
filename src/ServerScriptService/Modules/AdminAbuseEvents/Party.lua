--!strict

--[[
	Server-side logic for Party event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)
local AdminAbuseEvents = require(ServerScriptService.Game.Library.AdminAbuseEvents)
local GameSettings = require(ReplicatedStorage.Game.Library.GameSettings)
local Traits = require(ServerScriptService.Game.Library.Traits)
local FFlags = require(ServerScriptService.Library.FFlags)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local Functions = require(ReplicatedStorage.Library.Functions)
local MutationEvent = require(ServerScriptService.Game.Library.MutationEvent)
local Audio = require(ReplicatedStorage.Library.Audio)

local module = {}

-- Configuration
local CANNON_COUNT = 6
local TRAIT_DELAY = 6 -- Time in seconds before trait is applied
local MIN_FISH_TIME_REMAINING = 10 -- Minimum seconds remaining on fish

-- Shared state for this event
local lastCheckTime = 0
local isActive = false
local lastCannonId = 0
local fishSpawnTimer = 0

-- Fish spawn parts
local THINGS = workspace:WaitForChild("__THINGS")
local SPAWNS = THINGS:WaitForChild("FishSpawns")
local EASY = SPAWNS:WaitForChild("Easy")::BasePart
local HARD = SPAWNS:WaitForChild("Hard")::BasePart
local HARD_RATIO = 0.6

-- Type chances for fish spawning (copied from FishGenerator)
local typeChances = {
	["Normal"] = 79,
	["Shiny"] = 15,
	["Gold"] = 5,
	["Rainbow"] = 1,
}

-- Helper function to choose spawn part
local function chooseSpawnPart(): BasePart
	if math.random() < HARD_RATIO then
		return HARD
	end
	return EASY
end

-- Helper function to generate random point in part
local function randomPointIn(part: BasePart): CFrame
	local size = part.Size
	local lastCF = part.CFrame
	for attempt = 1, 5 do
		local offset = Vector3.new(
			(math.random() - 0.5) * size.X,
			(math.random() - 0.5) * size.Y,
			(math.random() - 0.5) * size.Z
		)
		local cf = part.CFrame * CFrame.new(offset)
		lastCF = cf

		-- Check against NoFishZones
		local inter = workspace:FindFirstChild("Interact")
		local zonesFolder = inter and inter:FindFirstChild("NoFishZones")
		local blocked = false
		if zonesFolder then
			for _, inst in ipairs(zonesFolder:GetDescendants()) do
				if inst:IsA("BasePart") then
					if Functions.IsPositionInPart(cf.Position, inst :: BasePart) then
						blocked = true
						break
					end
				end
			end
		end
		if not blocked then
			return cf
		end
	end
	-- Give up and use the last attempted point
	return lastCF
end

-- Helper function to choose party fish rarity (Rare+)
local function choosePartyFishRarity(): string?
	local rarityWeights = {
		Rare = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_RareWeight),
		Epic = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_EpicWeight),
		Legendary = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_LegendaryWeight),
		Mythical = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_MythicalWeight),
		God = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_GodWeight),
		Secret = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_SecretWeight),
	}
	
	local totalWeight = 0
	for _, weight in pairs(rarityWeights) do
		totalWeight += weight
	end
	
	if totalWeight <= 0 then
		return "Rare" -- Fallback
	end
	
	local roll = math.random() * totalWeight
	local acc = 0
	for rarityId, weight in pairs(rarityWeights) do
		acc += weight
		if roll <= acc then
			return rarityId
		end
	end
	
	return "Rare" -- Fallback
end

-- Helper function to choose fish by rarity
local function chooseFishByRarity(rarityId: string): any?
	local candidates = {}
	local totalWeight = 0
	for _, f in pairs(Directory.Fish) do
		if f.Rarity and f.Rarity._id == rarityId and not f.Rarity.PreventSpawning then
			table.insert(candidates, f)
			totalWeight += (f.RarityWeight or 0)
		end
	end
	if #candidates == 0 then return nil end
	if totalWeight <= 0 then
		return candidates[math.random(1, #candidates)]
	end
	local roll = math.random() * totalWeight
	local acc = 0
	for _, f in ipairs(candidates) do
		acc += (f.RarityWeight or 0)
		if roll <= acc then return f end
	end
	return candidates[#candidates]
end

-- Spawn a party fish
local function spawnPartyFish()
	-- Choose rarity (Rare+)
	local rarityId = choosePartyFishRarity()
	if not rarityId then
		warn("[Party Server] Failed to choose rarity for party fish")
		return
	end
	
	-- Choose specific fish
	local fishSchema = chooseFishByRarity(rarityId)
	if not fishSchema then
		warn("[Party Server] Failed to choose fish for rarity:", rarityId)
		return
	end
	
	-- Choose fish type (Normal, Shiny, Gold, Rainbow)
	local fishType = Functions.Lottery(typeChances)
	
	-- Determine mutation (check if Haunted event is active)
	local mutation: string? = nil
	if not fishSchema.LuckyBlockId and not fishSchema.SpecialItemFish then
		local isEventActive, eventId = MutationEvent.GetCurrentStatus()
		if isEventActive and eventId == "Haunted" then
			mutation = "Haunted"
		end
	end
	
	-- Choose spawn position
	local spawnPart = chooseSpawnPart()
	local spawnCFrame = randomPointIn(spawnPart)
	local yaw = math.rad(math.random(0, 359))
	local finalSpawnCFrame = CFrame.new(spawnCFrame.Position) * CFrame.Angles(0, yaw, 0)
	
	-- Generate visual data for client animation (20 random fish to cycle through)
	local visualData = {}
	local numVisuals = 20
	
	-- Get all fish for random cycling (exclude SpecialItemFish)
	local allFish = {}
	for fishId, schema in pairs(Directory.Fish) do
		if schema.Rarity and not schema.Rarity.PreventSpawning and not schema.SpecialItemFish and not schema.DisableSpawn then
			table.insert(allFish, fishId)
		end
	end
	
	-- Generate random visual data
	local lastFishId = nil
	for i = 1, numVisuals do
		local randomFishId
		repeat
			randomFishId = allFish[math.random(1, #allFish)]
		until randomFishId ~= lastFishId or #allFish == 1
		lastFishId = randomFishId
		
		local randomType = Functions.Lottery(typeChances)
		
		table.insert(visualData, {
			FishId = randomFishId,
			Type = randomType,
			Mutation = nil,
		})
	end
	
	-- Find PartyFishSpawn part to play sound at
	local spawnParts = CollectionService:GetTagged("PartyFishSpawn")
	local soundPosition = finalSpawnCFrame.Position -- Fallback to fish position
	if #spawnParts > 0 and spawnParts[1]:IsA("BasePart") then
		soundPosition = (spawnParts[1] :: BasePart).Position
	end
	
	-- Play pre-animation sound to all clients at the PartyFishSpawn location
	Audio.Play("rbxassetid://119218265790569", soundPosition, 1, 1, 150)
	
	-- Wait 3 seconds before starting the visual animation
	local preAnimationDelay = 3
	task.wait(preAnimationDelay)
	
	-- Notify all clients to play animation
	local currentTime = workspace:GetServerTimeNow()
	local serverSpawnDelay = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_ServerSpawnDelay)
	
	AdminAbuseEvents.Fire("Party", "FishSpawn", {
		FishId = fishSchema._id,
		Type = fishType,
		Mutation = mutation,
		Position = finalSpawnCFrame.Position,
		Orientation = Vector3.new(0, math.deg(yaw), 0),
		SpawnTime = currentTime + serverSpawnDelay,
		VisualData = visualData,
	})
		
	-- Schedule actual fish spawn on server (total delay is serverSpawnDelay, not including the preAnimationDelay we already waited)
	task.delay(serverSpawnDelay, function()
		-- Spawn the fish with Party trait at the exact position
		local traits = { Party = true }
		FishGenerator.ForceSpawnSpecificFish(fishSchema._id, fishType, mutation, false, traits, finalSpawnCFrame)
		
		-- Tell clients to play fireworks at the fish position
		AdminAbuseEvents.Fire("Party", "PlayFireworks", {
			Position = finalSpawnCFrame.Position,
		})
	end)
end

function module.OnStart()
	print("[Party Server] Event started")
	isActive = true
	lastCheckTime = 0
	lastCannonId = 0
	fishSpawnTimer = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_InitialDelay)
end

function module.Heartbeat(delta: number, time: number)
	if not isActive then
		return
	end
	
	-- Update fish spawn timer
	if FFlags.GetBoolean(FFlags.Keys.PartyFishSpawn_Enabled) then
		fishSpawnTimer -= delta
		
		if fishSpawnTimer <= 0 then
			-- Spawn a party fish asynchronously (so the 3 second delay doesn't block the heartbeat)
			task.spawn(spawnPartyFish)
			
			-- Reset timer to interval
			fishSpawnTimer = FFlags.GetNumber(FFlags.Keys.PartyFishSpawn_Interval)
		end
	end
	
	-- Check every 1 second for potential party cannon shot
	local secondsPassed = math.floor(time)
	local lastSecond = math.floor(lastCheckTime)
	
	if secondsPassed > lastSecond then
		lastCheckTime = time
		
		-- Check for party cannon shot based on FFlag chance
		local partyChance = FFlags.GetNumber(FFlags.Keys.PartyCannonChance)
		if math.random() >= partyChance then
			return
		end
	else
		return
	end
	
	-- Get all active fish
	local allActiveFish = FishGenerator.GetAllActive()
	local eligibleFish = {}
	
	-- Filter fish that have at least MIN_FISH_TIME_REMAINING seconds left
	local currentTime = workspace:GetServerTimeNow()
	for uid, fish in pairs(allActiveFish) do
		-- Calculate time remaining: DESPAWN_SECONDS - (now - fish.SpawnTime)
		local timeRemaining = fish.SpawnTime and (GameSettings.DespawnTime - (currentTime - fish.SpawnTime)) or 0
		if timeRemaining >= MIN_FISH_TIME_REMAINING then
			-- Check if fish doesn't already have Party trait
			if not Traits.HasTrait(fish, "Party") then
				table.insert(eligibleFish, {
					UID = uid,
					Fish = fish
				})
			end
		end
	end
	
	-- If we have eligible fish, pick one
	if #eligibleFish > 0 then
		local randomIndex = math.random(1, #eligibleFish)
		local targetData = eligibleFish[randomIndex]
		local targetUID = targetData.UID
		local targetFish = targetData.Fish
		
		if targetFish and targetFish.Model and targetFish.Model.PrimaryPart then
			local fishPosition = targetFish.Model.PrimaryPart.Position
			
			-- Pick a random cannon (not the same as last time)
			local cannonId: number
			if CANNON_COUNT == 1 then
				cannonId = 1
			else
				-- Pick a random cannon that's different from the last one
				repeat
					cannonId = math.random(1, CANNON_COUNT)
				until cannonId ~= lastCannonId
			end
			
			lastCannonId = cannonId
			
			-- Notify all clients about the party cannon shot
			AdminAbuseEvents.Fire("Party", "Shoot", {
				UID = targetUID,
				CannonId = cannonId,
				TargetPosition = fishPosition,
				TraitApplyTime = currentTime + TRAIT_DELAY,
			})
			
			-- Schedule trait application after TRAIT_DELAY seconds
			task.delay(TRAIT_DELAY, function()
				-- Check if fish is still active before applying trait
				local currentActiveFish = FishGenerator.GetAllActive()
				if currentActiveFish[targetUID] then
					FishGenerator.AddTrait(targetUID, "Party")
				else
					print(`[Party Server] Fish {targetUID} no longer active, skipping trait`)
				end
			end)
		end
	end
end

function module.OnStop()
	print("[Party Server] Event stopped")
	isActive = false
	lastCheckTime = 0
	lastCannonId = 0
	fishSpawnTimer = 0
end

return module

