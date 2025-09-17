--!strict

-- This script manages the server-side logic for the spinny wheel feature,
-- including validating spin requests, deducting spins from save data, and granting rewards.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Framework Modules
local Library = ServerScriptService:WaitForChild("Library")
local Network = require(Library.Network)
local Saving = require(Library.Saving)
local SpinnyWheelDirectory = require(ReplicatedStorage.Game.Library.Directory.SpinnyWheels)

-- {[player]: {reward: table, wheelId: string}}
local pendingRewards: {[Player]: {reward: any, wheelId: string}} = {}

--// Selects a random reward from the list based on weight.
local function selectReward(rewards: {any})
	local totalWeight = 0
	for _, reward in ipairs(rewards) do
		totalWeight += reward.Weight
	end

	local randomNumber = math.random() * totalWeight
	local cumulativeWeight = 0
	for i, reward in ipairs(rewards) do
		cumulativeWeight += reward.Weight
		if randomNumber <= cumulativeWeight then
			return reward, i
		end
	end
	
	-- Fallback to the last reward, should rarely happen.
	return rewards[#rewards], #rewards
end

--// Handles a spin request from the client.
Network.Fired("SpinWheel", function(player: Player, wheelId: string)
	local schema = SpinnyWheelDirectory[wheelId]
	if not schema then
		return
	end
	
	local saveData = Saving.Get(player)
	if not saveData then return end
	
	-- 1. Check if the player has spins for this wheel.
	local spinsForWheel = saveData.WheelSpins[wheelId] or 0
	if spinsForWheel <= 0 then
		-- Optionally, send a message to the player here.
		return
	end
	
	-- 2. Deduct one spin.
	saveData.WheelSpins[wheelId] = spinsForWheel - 1
	
	-- 3. Determine the reward and its index.
	local reward, rewardIndex = selectReward(schema.Rewards)
	
	-- 4. Store the pending reward and wheelId instead of giving it immediately.
	pendingRewards[player] = {
		reward = reward,
		wheelId = wheelId,
	}
	
	-- 5. Tell the client which reward was won so it can play the animation.
	Network.Fire(player, "SpinWheelResult", wheelId, rewardIndex)
end)

--// Listen for the client to tell us the animation is done, then give the reward.
Network.Fired("SpinAnimationComplete", function(player: Player)
	local pending = pendingRewards[player]
	if not pending then
		return
	end
	
	local schema = SpinnyWheelDirectory[pending.wheelId]
	if schema then
		schema.GiveReward(player, pending.reward)
	end
	
	pendingRewards[player] = nil
end)

--// Clean up pending rewards if a player leaves mid-spin.
Players.PlayerRemoving:Connect(function(player)
	pendingRewards[player] = nil
end)