--!strict
--!native

--[[
	Client-side commands for the Limited Mythical Offer system.

	API:
		CanPurchase() -> boolean
		GetPurchaseTimeLeft() -> number (seconds)
]]

local Network = require(game.ReplicatedStorage.Library.Client.Network)

local expireAt: number = 0 -- server-reported hard expiration time (no grace exposed to client)
local isActive: boolean = false

local LimitedMythicalOfferCmds = {}

function LimitedMythicalOfferCmds.CanPurchase(): boolean
	return isActive and LimitedMythicalOfferCmds.GetPurchaseTimeLeft() > 0
end

function LimitedMythicalOfferCmds.GetPurchaseTimeLeft(): number
	local now = workspace:GetServerTimeNow()
	local remaining = math.max(0, expireAt - now)
	return remaining
end

-- Receive push updates from the server
Network.Fired("LimitedMythicalOffer_Begun", function(expireHard: number)
	expireAt = tonumber(expireHard) or 0
	isActive = true
end)

Network.Fired("LimitedMythicalOffer_Sync", function(expireHard: number)
	expireAt = tonumber(expireHard) or 0
end)

Network.Fired("LimitedMythicalOffer_Status", function(active: boolean)
	isActive = active == true
end)

return LimitedMythicalOfferCmds


