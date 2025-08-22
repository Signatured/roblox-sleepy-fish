--!strict

-- This client library caches leaderboard data received from the server
-- and provides functions to access it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Framework Modules
local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)
local Event = require(Library.Modules.Event)

type LeaderboardData = {[number]: number}

local LeaderboardCmds = {}

-- {[leaderboardId]: LeaderboardData}
local leaderboardCache: {[string]: LeaderboardData} = {}

LeaderboardCmds.LeaderboardUpdated = Event.new()

--// Gets the cached data for a specific leaderboard.
function LeaderboardCmds.GetData(leaderboardId: string): LeaderboardData?
	return leaderboardCache[leaderboardId]
end

-- HOOKS
-- Listen for updates from the server and store the new data.
Network.Fired("UpdateLeaderboard", function(leaderboardId: string, data: LeaderboardData)
	leaderboardCache[leaderboardId] = data
	LeaderboardCmds.LeaderboardUpdated:FireAsync(leaderboardId, data)
end)

-- When a client joins, it should request the latest data for all known leaderboards.
-- This part is now handled by the LeaderboardRenderer script.

return LeaderboardCmds 