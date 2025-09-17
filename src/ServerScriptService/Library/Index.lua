--!strict

-- Server-side Index utilities for tracking and evaluating a player's fish index

-- Services and shared directories (absolute requires only)
local Directory = require(game.ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Saving = require(game.ServerScriptService.Library.Saving)

export type IndexData = {
	Normal: boolean?,
	Shiny: boolean?,
	Gold: boolean?,
	Rainbow: boolean?,
	BloodMoon: boolean?, -- Tracks if caught with Bloodfish mutation
}

local Index = {}

local function ensureEntry(map: {[string]: IndexData}, fishId: string): IndexData
	local entry = map[fishId]
	if not entry then
		entry = { Normal = false, Shiny = false, Gold = false, Rainbow = false, BloodMoon = false }
		map[fishId] = entry
	else
		-- Ensure backward compatibility - add BloodMoon field if it doesn't exist
		if entry.BloodMoon == nil then
			entry.BloodMoon = false
		end
	end
	return entry
end

local function markVariant(entry: IndexData, fishType: FishTypes.fish_type)
	if fishType == "Normal" then
		entry.Normal = true
	elseif fishType == "Shiny" then
		entry.Shiny = true
	elseif fishType == "Gold" then
		entry.Gold = true
	elseif fishType == "Rainbow" then
		entry.Rainbow = true
	end
end

function Index.Add(player: Player, fishId: string, fishType: FishTypes.fish_type, mutation: FishTypes.fish_mutation_type?)
	local save = Saving.Get(player)
	if not save then return end

	local map = save.Index :: any
	local entry = ensureEntry(map, fishId)
	markVariant(entry, fishType)
	
	-- Mark BloodMoon if fish has Bloodfish mutation
	if mutation == "Bloodfish" then
		entry.BloodMoon = true
	end
end

local function entryComplete(entry: IndexData?): boolean
	if not entry then return false end
	return entry.Normal == true and entry.Shiny == true and entry.Gold == true and entry.Rainbow == true and entry.BloodMoon == true
end

function Index.IsCompleted(player: Player): boolean
	local save = Saving.Get(player)
	if not save then return false end

	local map = save.Index :: any
	if type(map) ~= "table" then return false end

	for fishId, dir in pairs(Directory.Fish) do
		if dir.Rarity and dir.Rarity._id == "Exclusive" then
			continue
		end
		if not entryComplete(map[fishId]) then
			return false
		end
	end
	return true
end

--[[
	Checks if a player has caught a specific fish with the Bloodfish mutation during Blood Moon events.
	
	@param player - The player to check
	@param fishId - The fish ID to check for BloodMoon variant
	@return boolean - Whether the player has the BloodMoon variant of this fish
]]
function Index.HasBloodMoon(player: Player, fishId: string): boolean
	local save = Saving.Get(player)
	if not save then return false end

	local map = save.Index :: any
	if type(map) ~= "table" then return false end
	
	local entry = map[fishId]
	return entry and entry.BloodMoon == true or false
end

--[[
	Gets the total count of fish species that have been caught with BloodMoon mutation.
	
	@param player - The player to check
	@return number - Count of fish species with BloodMoon variant caught
]]
function Index.GetBloodMoonCount(player: Player): number
	local save = Saving.Get(player)
	if not save then return 0 end

	local map = save.Index :: any
	if type(map) ~= "table" then return 0 end
	
	local count = 0
	for fishId, entry in pairs(map) do
		if entry and entry.BloodMoon == true then
			count += 1
		end
	end
	return count
end

return Index


