--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Event = require(ReplicatedStorage.Library.Modules.Event)

local DailyQuestsCmds = {}

local cache = nil
DailyQuestsCmds.Updated = Event.new()

function DailyQuestsCmds.Get()
	return cache
end

function DailyQuestsCmds.Sell()
	pcall(function()
		Network.Fire("DailyQuests_Sell")
	end)
end

function DailyQuestsCmds.Claim()
	pcall(function()
		Network.Fire("DailyQuests_Claim")
	end)
end

Network.Fired("DailyQuests_Sync", function(data)
	cache = data
	DailyQuestsCmds.Updated:FireAsync(data)
end)

return DailyQuestsCmds






























