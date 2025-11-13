--!strict

--[[
	Server-side PartyMachine library.
	Handles players contributing fish to earn party points towards starting a Party event.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Saving = require(ServerScriptService.Library.Saving)
local Network = require(ServerScriptService.Library.Network)
local Fish = require(ServerScriptService.Game.Library.Fish)
local FFlags = require(ServerScriptService.Library.FFlags)
local AdminAbuseEvents = require(ServerScriptService.Game.Library.AdminAbuseEvents)

local PartyMachine = {}

-- Module state
local currentPoints = 0
local isEventActive = false
local eventStopScheduled = false

-- Get point value for a rarity
local function getPointsForRarity(rarityId: string): number
	local flagKey = `PartyPoints_{rarityId}`
	if FFlags.Keys[flagKey] then
		return FFlags.GetNumber(FFlags.Keys[flagKey])
	end
	return 0
end

-- Get the current point goal from FFlags
local function getPointGoal(): number
	return FFlags.GetNumber(FFlags.Keys.PartyPointGoal)
end

-- Get the event duration from FFlags
local function getEventDuration(): number
	return FFlags.GetNumber(FFlags.Keys.PartyEventDuration)
end

-- Start the Party event
local function startPartyEvent()
	if isEventActive then
		return
	end
	
	isEventActive = true
	eventStopScheduled = false
	
	-- Start the Party admin abuse event
	AdminAbuseEvents.Start("Party", true) -- true for local override
	
	print("[PartyMachine] Party event started!")
	
	-- Broadcast to all clients that the event has started
	Network.FireAll("PartyMachine_EventStarted")
	
	-- Schedule the event to stop after the duration
	local duration = getEventDuration()
	task.delay(duration, function()
		if eventStopScheduled then
			return -- Already stopped
		end
		eventStopScheduled = true
		
		-- Stop the Party event
		AdminAbuseEvents.Stop("Party")
		
		-- Reset points
		currentPoints = 0
		isEventActive = false
		
		print("[PartyMachine] Party event ended!")
		
		-- Broadcast to all clients that the event has ended
		Network.FireAll("PartyMachine_EventEnded")
	end)
end

-- Submit fish for points
function PartyMachine.SubmitPoints(player: Player, fishUids: {string}): (boolean, string?, number?)
	-- Check if event is already active
	if isEventActive then
		return false, "The party is already in progress!", nil
	end
	
	-- Check if admin abuse Party event is active
	if AdminAbuseEvents.IsActive("Party") then
		return false, "The party is already in progress!", nil
	end
	
	-- Get player save
	local save = Saving.Get(player)
	if not save then
		return false, "Something went wrong!", nil
	end
	
	-- Validate that player has all fish
	local fishDataList: {FishTypes.data_schema} = {}
	for _, uid in ipairs(fishUids) do
		local fishData = Fish.GetFromInventory(player, uid)
		if not fishData then
			return false, "Something went wrong!", nil
		end
		
		-- Check if fish is Exclusive rarity or SpecialItemFish
		local fishSchema = Directory.Fish[fishData.FishId]
		if fishSchema and (fishSchema.Rarity._id == "Exclusive" or fishSchema.SpecialItemFish) then
			return false, "Something went wrong!", nil
		end
		
		table.insert(fishDataList, fishData)
	end
	
	-- Calculate points for each fish
	local fishWithPoints: {{data: FishTypes.data_schema, points: number, rarityId: string}} = {}
	for _, fishData in ipairs(fishDataList) do
		local fishSchema = Directory.Fish[fishData.FishId]
		if fishSchema then
			local rarityId = fishSchema.Rarity._id
			local points = getPointsForRarity(rarityId)
			table.insert(fishWithPoints, {
				data = fishData,
				points = points,
				rarityId = rarityId
			})
		end
	end
	
	-- Sort by points (lowest first)
	table.sort(fishWithPoints, function(a, b)
		return a.points < b.points
	end)
	
	-- Calculate how many points we can add
	local pointGoal = getPointGoal()
	local remainingSpace = pointGoal - currentPoints
	local pointsToAdd = 0
	local fishToRemove: {string} = {}
	
	-- Add fish in order until we hit the goal
	for _, entry in ipairs(fishWithPoints) do
		if currentPoints >= pointGoal then
			break
		end
		
		local pointsFromThisFish = math.min(entry.points, remainingSpace)
		pointsToAdd = pointsToAdd + pointsFromThisFish
		remainingSpace = remainingSpace - pointsFromThisFish
		currentPoints = currentPoints + pointsFromThisFish
		table.insert(fishToRemove, entry.data.UID)
		
		if currentPoints >= pointGoal then
			break
		end
	end
	
	-- Remove the fish from player's inventory
	for _, uid in ipairs(fishToRemove) do
		Fish.Take(player, uid)
	end
	
	-- Broadcast updated points to all clients
	Network.FireAll("PartyMachine_PointsUpdated", currentPoints)
	
	-- Check if we've reached the goal
	if currentPoints >= pointGoal then
		startPartyEvent()
	end
	
	return true, nil, pointsToAdd
end

-- Get current state
function PartyMachine.GetState(): {Points: number, IsEventActive: boolean, PointGoal: number}
	return {
		Points = currentPoints,
		IsEventActive = isEventActive,
		PointGoal = getPointGoal()
	}
end

-- Network handlers
Network.Invoked("PartyMachine_SubmitPoints", function(player: Player, fishUids: {string})
	if typeof(fishUids) ~= "table" then
		return false, "Something went wrong!", nil
	end
	
	-- Validate all entries are strings
	for _, uid in ipairs(fishUids) do
		if typeof(uid) ~= "string" then
			return false, "Something went wrong!", nil
		end
	end
	
	return PartyMachine.SubmitPoints(player, fishUids)
end)

Network.Invoked("PartyMachine_GetState", function(_player: Player)
	return PartyMachine.GetState()
end)

return PartyMachine

