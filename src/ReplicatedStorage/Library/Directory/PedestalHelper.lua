--!strict

local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)

local PedestalHelper = {}

-- Calculate the total number of accessible pedestals based on ExtraFloors and PedestalGroupsUnlocked
function PedestalHelper.GetAccessiblePedestalCount(extraFloors: number?, pedestalGroupsUnlocked: number?): number
	if not extraFloors or extraFloors == 0 then
		return GameSettings.DefaultPedestalCount
	end
	
	-- Start with the base pedestal count for this floor
	local count = GameSettings.ExtraFloorPedestalCounts[extraFloors] or GameSettings.DefaultPedestalCount
	
	-- Check if this floor has purchasable pedestal groups
	local groups = GameSettings.PedestalGroups[extraFloors]
	if not groups or not pedestalGroupsUnlocked or pedestalGroupsUnlocked == 0 then
		return count
	end
	
	-- Add pedestals from each unlocked group
	for i = 1, math.min(pedestalGroupsUnlocked, #groups) do
		local group = groups[i]
		count = count + #group.Pedestals
	end
	
	return count
end

-- Get the next purchasable pedestal group for a given floor
function PedestalHelper.GetNextPedestalGroup(extraFloors: number?, pedestalGroupsUnlocked: number?): {Pedestals: {number}, Price: number}?
	if not extraFloors or extraFloors == 0 then
		return nil
	end
	
	local groups = GameSettings.PedestalGroups[extraFloors]
	if not groups then
		return nil
	end
	
	local nextGroupIndex = (pedestalGroupsUnlocked or 0) + 1
	return groups[nextGroupIndex]
end

-- Get the total number of groups available for a floor
function PedestalHelper.GetTotalGroupsForFloor(extraFloors: number?): number
	if not extraFloors or extraFloors == 0 then
		return 0
	end
	
	local groups = GameSettings.PedestalGroups[extraFloors]
	return groups and #groups or 0
end

-- Get the maximum pedestals possible for a floor (including all groups)
function PedestalHelper.GetMaxPedestalsForFloor(extraFloors: number?): number
	if not extraFloors or extraFloors == 0 then
		return GameSettings.DefaultPedestalCount
	end
	
	local baseCount = GameSettings.ExtraFloorPedestalCounts[extraFloors] or GameSettings.DefaultPedestalCount
	local groups = GameSettings.PedestalGroups[extraFloors]
	
	if not groups then
		return baseCount
	end
	
	local totalPedestals = baseCount
	for _, group in groups do
		totalPedestals = totalPedestals + #group.Pedestals
	end
	
	return totalPedestals
end

return PedestalHelper

