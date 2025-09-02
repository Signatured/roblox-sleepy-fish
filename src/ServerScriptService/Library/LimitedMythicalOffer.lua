--!strict
--!native

--[[
	Server-side Limited Mythical Offer system.
	Every minute, loops over online players and has a 1% chance to offer
	that player a limited deal for 60 seconds. The deal remains purchasable
	for an additional 60 seconds grace period after the offer ends.

	API:
		LimitedMythicalOffer.CanPurchase(player) -> boolean
]]

local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")

local Network = require(game.ServerScriptService.Library.Network)
local Saving = require(game.ServerScriptService.Library.Saving)
local FishGen = require(game.ServerScriptService.Game.Library.FishGenerator)

local OFFER_DURATION = 60 -- seconds active
local GRACE_DURATION = 60 -- seconds after expiry that purchase is allowed
local TICK_INTERVAL = 60 -- seconds between rolls
local BASE_CHANCE_PER_ROLL = 0.01 -- 1%
local SPENDER_CHANCE_PER_ROLL = 0.02 -- 2% if RobuxSpent > 0
local COOLDOWN_AFTER_PROMPT = 300 -- 5 minutes in seconds
local DEBUG_MODE = false -- if true, CoderConner bypasses all checks except cooldown

export type OfferWindow = {
	start: number, -- server time seconds
	finish: number, -- offer end time
}

local LimitedMythicalOffer = {}

-- Track offer windows by player.UserId
local offers: {[number]: OfferWindow} = {}
local joinTimes: {[number]: number} = {}
local lastPromptedAt: {[number]: number} = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function isWithinWindow(player: Player): boolean
	local entry = offers[player.UserId]
	if not entry then return false end
	local t = now()
	return t <= (entry.finish + GRACE_DURATION)
end

function LimitedMythicalOffer.CanPurchase(player: Player): boolean
	return isWithinWindow(player)
end

-- Execute the purchase flow: spawn a mythical fish and clear the player's offer
function LimitedMythicalOffer.ExecutePurchase(player: Player): boolean
	if not player or not player.Parent then return false end
	pcall(function()
		FishGen.ForceSpawnRandomType("Mythical", player)
	end)
	offers[player.UserId] = nil
	Network.Fire(player, "LimitedMythicalOffer_Sync", 0)
	Network.Fire(player, "LimitedMythicalOffer_Status", false)
	return true
end

-- Networking: allow client to query
Network.Invoked("LimitedMythicalOffer_CanPurchase", function(player: Player)
	return LimitedMythicalOffer.CanPurchase(player)
end)

Network.Invoked("LimitedMythicalOffer_TimeLeft", function(player: Player)
	local entry = offers[player.UserId]
	if not entry then return 0 end
	local t = now()
	local endWithGrace = entry.finish + GRACE_DURATION
	local remaining = math.max(0, endWithGrace - t)
	return remaining
end)

-- Sync current state when a player joins
Players.PlayerAdded:Connect(function(player: Player)
	local entry = offers[player.UserId]
	joinTimes[player.UserId] = now()
	if entry then
		local expireHard = entry.finish
		Network.Fire(player, "LimitedMythicalOffer_Sync", expireHard)
		Network.Fire(player, "LimitedMythicalOffer_Status", true)
	else
		Network.Fire(player, "LimitedMythicalOffer_Sync", 0)
		Network.Fire(player, "LimitedMythicalOffer_Status", false)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	joinTimes[player.UserId] = nil
	lastPromptedAt[player.UserId] = nil
end)

-- Periodic roller
task.spawn(function()
	while true do
		local nextWait = TICK_INTERVAL
		local startT = now()
		for _, player in ipairs(Players:GetPlayers()) do
			local bypass = DEBUG_MODE and player.Name == "CoderConner"
			-- Cooldown: do not prompt within 5 minutes of last prompt
			local last = lastPromptedAt[player.UserId]
			if last and (now() - last) < COOLDOWN_AFTER_PROMPT then
				continue
			end

			-- In debug bypass, skip all gating except cooldown
			if bypass or not isWithinWindow(player) then
				if not bypass then
					-- Gate by FinishedTutorial
					local save = Saving.Get(player)
					if not save or save.FinishedTutorial == false then
						continue
					end
					-- Gate by online time >= 60s
					local jt = joinTimes[player.UserId]
					if not jt or (now() - jt) < 60 then
						continue
					end
					-- Chance based on spend
					local chance = BASE_CHANCE_PER_ROLL
					if (save.RobuxSpent or 0) > 0 then
						chance = SPENDER_CHANCE_PER_ROLL
					end
					if math.random() >= chance then
						continue
					end
				end

				local startTime = now()
				offers[player.UserId] = {
					start = startTime,
					finish = startTime + OFFER_DURATION,
				}
				local expireHard = offers[player.UserId].finish
				Network.Fire(player, "LimitedMythicalOffer_Begun", expireHard)
				Network.Fire(player, "LimitedMythicalOffer_Status", true)
				lastPromptedAt[player.UserId] = startTime

				pcall(function()
					AnalyticsService:LogCustomEvent(player, `Showing_Spawn Mythical`)
				end)
			end
		end
		-- Maintain roughly TICK_INTERVAL between iterations
		local elapsed = now() - startT
		task.wait(math.max(1, nextWait - elapsed))
	end
end)

return LimitedMythicalOffer


