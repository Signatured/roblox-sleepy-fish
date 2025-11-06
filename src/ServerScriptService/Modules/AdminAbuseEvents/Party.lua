--!strict

--[[
	Server-side logic for Party event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)
local AdminAbuseEvents = require(ServerScriptService.Game.Library.AdminAbuseEvents)
local GameSettings = require(ReplicatedStorage.Game.Library.GameSettings)
local Traits = require(ServerScriptService.Game.Library.Traits)
local FFlags = require(ServerScriptService.Library.FFlags)

local module = {}

-- Configuration
local CANNON_COUNT = 6
local TRAIT_DELAY = 6 -- Time in seconds before trait is applied
local MIN_FISH_TIME_REMAINING = 10 -- Minimum seconds remaining on fish

-- Shared state for this event
local lastCheckTime = 0
local isActive = false
local lastCannonId = 0

function module.OnStart()
	print("[Party Server] Event started")
	isActive = true
	lastCheckTime = 0
	lastCannonId = 0
end

function module.Heartbeat(delta: number, time: number)
	if not isActive then
		return
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
					local success = FishGenerator.AddTrait(targetUID, "Party")
					if success then
						print(`[Party Server] Applied Party trait to fish {targetUID}`)
					end
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
end

return module

