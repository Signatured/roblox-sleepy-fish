--!strict

-- Server relay for global admin messages via MessagingService

local MessagingService = game:GetService("MessagingService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)

local TOPIC = "SleepyFish:AdminGlobalMessage"
local FORCE_RARITY_TOPIC = "SleepyFish:ForceRarity"

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


