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
local function selectReward(rewards: {any}, isPaidSpin: boolean)
    -- Compute total and base probabilities
    local totalBase = 0
    for _, reward in ipairs(rewards) do
        totalBase += reward.Weight
    end

    local adjustedWeights = table.create(#rewards)
    local totalAdjusted = 0
    for idx, reward in ipairs(rewards) do
        local w = reward.Weight
        if isPaidSpin and totalBase > 0 then
            local baseChance = w / totalBase
            if baseChance <= 0.05 then
                w = w * 2 -- 2x luck for <=5% items on paid spins
            end
        end
        adjustedWeights[idx] = w
        totalAdjusted += w
    end

    local r = math.random() * totalAdjusted
    local cumulative = 0
    for i, w in ipairs(adjustedWeights) do
        cumulative += w
        if r <= cumulative then
            return rewards[i], i
        end
    end
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
	
    -- Determine spin source: use free first, then paid
    saveData.Wheels[wheelId] = saveData.Wheels[wheelId] or { Free = 0, Paid = 0, FreeNextAt = nil }
    local wheel = saveData.Wheels[wheelId]

    local spinType: string? = nil
    if (wheel.Free or 0) > 0 then
        spinType = "free"
        wheel.Free -= 1
        -- Start the 3-hour timer for next free spin only when a free spin is used
        wheel.FreeNextAt = workspace:GetServerTimeNow() + (3 * 60 * 60)
    elseif (wheel.Paid or 0) > 0 then
        spinType = "paid"
        wheel.Paid -= 1
    end

    if not spinType then
        return -- No spins available
    end

    -- Determine the reward and its index, applying paid-spin luck if applicable
    local reward, rewardIndex = selectReward(schema.Rewards, spinType == "paid")
	
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

-- Award and schedule free spins on save load
Saving.SaveAdded:Connect(function(player: Player)
    local saveData = Saving.Get(player)
    if not saveData then return end

    -- Initialize containers if missing
    saveData.Wheels = saveData.Wheels or {}

    local nowT = workspace:GetServerTimeNow()

    for wheelId, _dir in pairs(SpinnyWheelDirectory) do
        saveData.Wheels[wheelId] = saveData.Wheels[wheelId] or { Free = 0, Paid = 0, FreeNextAt = nil }
        local wheel = saveData.Wheels[wheelId]
        local free = wheel.Free or 0
        local nextAt = wheel.FreeNextAt

        if nextAt == nil and free == 0 then
            -- First time seeing this wheel: schedule initial free spin 15 minutes after first join
            wheel.FreeNextAt = nowT + (15 * 60)
        end

        -- If a timer exists and has elapsed and player has no free spin queued, grant exactly 1 and clear timer
        nextAt = wheel.FreeNextAt
        if typeof(nextAt) == "number" and nextAt <= nowT and free == 0 then
            wheel.Free = 1
            wheel.FreeNextAt = nil
        end
    end
end)