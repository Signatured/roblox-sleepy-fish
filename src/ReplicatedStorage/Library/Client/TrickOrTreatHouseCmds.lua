--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Save = require(ReplicatedStorage.Library.Client.Save)
local Network = require(ReplicatedStorage.Library.Client.Network)

local TrickOrTreatHouseCmds = {}

--[[
	Checks if a house is currently on cooldown.
	
	@param houseId The house ID (number)
	@return boolean Whether the house is on cooldown
]]
function TrickOrTreatHouseCmds.IsOnCooldown(houseId: number): boolean
	local save = Save.Get()
	if not save or not save.TrickOrTreatHouses then
		return false
	end
	
	local cooldownEnd = save.TrickOrTreatHouses[tostring(houseId)]
	if not cooldownEnd then
		return false
	end
	
	return workspace:GetServerTimeNow() <= cooldownEnd
end

--[[
	Gets the remaining cooldown time for a house.
	
	@param houseId The house ID (number)
	@return number Seconds remaining on cooldown (or 0 if not on cooldown)
]]
function TrickOrTreatHouseCmds.GetHouseCooldown(houseId: number): number
	local save = Save.Get()
	if not save or not save.TrickOrTreatHouses then
		return 0
	end
	
	local cooldownEnd = save.TrickOrTreatHouses[tostring(houseId)]
	if not cooldownEnd then
		return 0
	end
	
	local remaining = cooldownEnd - workspace:GetServerTimeNow()
	return math.max(0, remaining)
end

--[[
	Requests to trick or treat at a house.
	Checks the local save first before making the network request.
	
	@param houseId The house ID (number)
]]
function TrickOrTreatHouseCmds.RequestTrickOrTreat(houseId: number)
	local save = Save.Get()
	if not save then return end
	
	save.TrickOrTreatHouses = save.TrickOrTreatHouses or {}
	
	-- Check if we can trick or treat at this house
	local cooldownEnd = save.TrickOrTreatHouses[tostring(houseId)]
	local canTrickOrTreat = not cooldownEnd or workspace:GetServerTimeNow() > cooldownEnd
	
	if canTrickOrTreat then
		-- Request from server
		pcall(function()
			Network.Fire("TrickOrTreatHouses_Request", houseId)
		end)
	end
end

return TrickOrTreatHouseCmds

