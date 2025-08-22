--!strict

-- This library manages all server-side logic for leaderboards, including
-- DataStore management, caching, and providing player score/placement data.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Framework Modules
local Library = ServerScriptService:WaitForChild("Library")
local Network = require(Library.Network)
local LeaderboardDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Leaderboards)
local Event = require(game.ReplicatedStorage.Library.Modules.Event)

type LeaderboardData = {[number]: number}

local Leaderboards = {}

-- {[leaderboardId]: OrderedDataStore}
local leaderboardDataStores = {}

-- {[leaderboardId]: LeaderboardData}
local leaderboardCache: {[string]: LeaderboardData} = {}

local leaderboardsReady = false
local pendingRequests: {{player: Player, leaderboardId: string}} = {}
local readyEvent = Event.new()

--// Gets or creates the OrderedDataStore for a given leaderboard.
local function getDataStore(leaderboardId: string): OrderedDataStore
	if leaderboardDataStores[leaderboardId] then
		return leaderboardDataStores[leaderboardId]
	end
	
	local dataStore = DataStoreService:GetOrderedDataStore("Leaderboard_" .. leaderboardId)
	leaderboardDataStores[leaderboardId] = dataStore
	return dataStore
end

--// Updates a single player's score on a specific leaderboard.
function Leaderboards.UpdateUserScore(leaderboardId: string, player: Player)
	local schema = LeaderboardDirectory[leaderboardId]
	if not schema then return end

	local success, score = pcall(schema.ScoreGetter, player)
	if not success or typeof(score) ~= "number" then
		warn(`[Leaderboards] ScoreGetter for '{leaderboardId}' failed or returned non-number for {player.Name}: {tostring(score)}`)
		return
	end
	
	local dataStore = getDataStore(leaderboardId)
	local success, err = pcall(function()
		dataStore:SetAsync(tostring(player.UserId), score)
	end)
	
	if not success then
		warn(`[Leaderboards] Failed to update score for {player.Name} on '{leaderboardId}': {err}`)
	end
end

--// Fetches the top entries from a DataStore and updates the server-side cache.
function Leaderboards.FetchTopEntries(leaderboardId: string)
	local schema = LeaderboardDirectory[leaderboardId]
	if not schema then return end

	local amountToDisplay = schema.DisplayAmount or 100
	
	local dataStore = getDataStore(leaderboardId)
	local pages = dataStore:GetSortedAsync(false, amountToDisplay) -- false for descending (highest first)
	local data = pages:GetCurrentPage()
	
	local newCache: LeaderboardData = {}
	for _, item in ipairs(data) do
        local key = tonumber(item.key)
        if key then
            newCache[key] = item.value
        end
	end
	
	leaderboardCache[leaderboardId] = newCache
	
	-- Send the updated data to all clients.
	Network.FireAll("UpdateLeaderboard", leaderboardId, newCache)
end

--// Gets a player's score and placement from the cache.
function Leaderboards.GetPlayerRank(leaderboardId: string, player: Player): (number?, number?)
	local cache = leaderboardCache[leaderboardId]
	if not cache then return nil, nil end

	local score = cache[player.UserId]
	if not score then
		-- If they're not in the cache but are online, just return their current score from the ScoreGetter.
		local schema = LeaderboardDirectory[leaderboardId]
		if schema then
			local success, currentScore = pcall(schema.ScoreGetter, player)
			if success then
				return nil, currentScore
			end
		end
		return nil, nil
	end

	-- To find the rank, we need to count how many players have a higher score.
	local rank = 1
	for _, otherScore in pairs(cache) do
		if otherScore > score then
			rank += 1
		end
	end
	
	return rank, score
end

--// Main update loop to refresh all leaderboards from their DataStores.
local function runUpdateLoop()
	task.spawn(function()
		-- Initial fetch on server startup
		task.wait(5) -- Give time for directories to load
		for id in pairs(LeaderboardDirectory) do
			Leaderboards.FetchTopEntries(id)
		end
		
		leaderboardsReady = true
		readyEvent:FireAsync()
		
		while true do
			-- Wait for a random interval between 15 and 30 minutes.
			task.wait(math.random(15 * 60, 30 * 60))
			
			for id in pairs(LeaderboardDirectory) do
				Leaderboards.FetchTopEntries(id)
			end
		end
	end)
end

--// Periodic loop to update the scores of all online players.
local function runOnlinePlayerUpdateLoop()
	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				for id in pairs(LeaderboardDirectory) do
					Leaderboards.UpdateUserScore(id, player)
				end
			end
			-- Wait 30 seconds before updating online players again.
			task.wait(30)
		end
	end)
end

-- HOOKS
-- Update a player's score when they leave.
Players.PlayerRemoving:Connect(function(player)
	for id in pairs(LeaderboardDirectory) do
		Leaderboards.UpdateUserScore(id, player)
	end
end)

-- When a client requests data, either send it immediately or queue it.
Network.Fired("RequestLeaderboardUpdate", function(player: Player, leaderboardId: string)
	if leaderboardsReady then
		local cache = leaderboardCache[leaderboardId]
		if cache then
			Network.Fire(player, "UpdateLeaderboard", leaderboardId, cache)
		end
	else
		table.insert(pendingRequests, {player = player, leaderboardId = leaderboardId})
	end
end)

-- When the leaderboards are ready, process any queued requests.
readyEvent:Connect(function()
	for _, req in ipairs(pendingRequests) do
		local cache = leaderboardCache[req.leaderboardId]
		if cache then
			Network.Fire(req.player, "UpdateLeaderboard", req.leaderboardId, cache)
		end
	end
	-- Clear the queue
	pendingRequests = {}
end)

-- When a client requests its personal rank, find it in the cache and return it.
Network.Invoked("GetPlayerRank", function(player: Player, leaderboardId: string)
	return Leaderboards.GetPlayerRank(leaderboardId, player)
end)

runUpdateLoop()
runOnlinePlayerUpdateLoop()

return Leaderboards 