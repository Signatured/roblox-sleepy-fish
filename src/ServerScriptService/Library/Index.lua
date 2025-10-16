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
	BloodMoon: boolean?,
	Galaxy: boolean?,
	Spooky: boolean?,
}

local Index = {}

local function GetMutationId(mutation: string?): string?
	if not mutation then
		return nil
	end
	
	local mutationDir = Directory.Mutations[mutation]
	if mutationDir then
		if mutationDir._id == "Bloodfish" then -- Bloodfish was done weird originally, so we need to convert it to the new format
			return "BloodMoon"
		else
			return mutationDir._id
		end
	end

	return nil
end

local function ensureEntry(map: {[string]: IndexData}, fishId: string): IndexData
	local entry = map[fishId]
	if not entry then
		entry = { Normal = false, Shiny = false, Gold = false, Rainbow = false, BloodMoon = false, Galaxy = false, Spooky = false }
		map[fishId] = entry
	else
		-- Ensure backward compatibility - add BloodMoon field if it doesn't exist
		if entry.BloodMoon == nil then
			entry.BloodMoon = false
		end
		-- Ensure backward compatibility - add Galaxy field if it doesn't exist
		if entry.Galaxy == nil then
			entry.Galaxy = false
		end
		-- Ensure backward compatibility - add Spooky field if it doesn't exist
		if entry.Spooky == nil then
			entry.Spooky = false
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

function Index.Add(player: Player, fishId: string, fishType: FishTypes.fish_type, mutation: string?)
	local save = Saving.Get(player)
	if not save then return end

	local map = save.Index :: any
	local entry = ensureEntry(map, fishId)
	markVariant(entry, fishType)
	
	-- Mark BloodMoon if fish has Bloodfish mutation
	if mutation then
		local mutationId = GetMutationId(mutation)
		if mutationId then
			entry[mutationId] = true
		end
	end
end

local function entryComplete(entry: IndexData?): boolean
	if not entry then return false end
	return entry.Normal == true and entry.Shiny == true and entry.Gold == true and entry.Rainbow == true and entry.BloodMoon == true and entry.Galaxy == true and entry.Spooky == true
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
	Checks if a player has caught a specific fish with the Bloodfish mutation during Blood Moon events.
	
	@param player - The player to check
	@param fishId - The fish ID to check for BloodMoon variant
	@return boolean - Whether the player has the BloodMoon variant of this fish
]]
function Index.HasGalaxy(player: Player, fishId: string): boolean
	local save = Saving.Get(player)
	if not save then return false end

	local map = save.Index :: any
	if type(map) ~= "table" then return false end
	
	local entry = map[fishId]
	return entry and entry.Galaxy == true or false
end

--[[
	Checks if a player has caught a specific fish with the Spooky mutation during Spooky events.
	
	@param player - The player to check
	@param fishId - The fish ID to check for Spooky variant
	@return boolean - Whether the player has the Spooky variant of this fish
]]
function Index.HasSpooky(player: Player, fishId: string): boolean
	local save = Saving.Get(player)
	if not save then return false end

	local map = save.Index :: any
	if type(map) ~= "table" then return false end
	
	local entry = map[fishId]
	return entry and entry.Spooky == true or false
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

--[[
	Gets the total count of fish species that have been caught with Galaxy mutation.
	
	@param player - The player to check
	@return number - Count of fish species with Galaxy variant caught
]]
function Index.GetGalaxyCount(player: Player): number
	local save = Saving.Get(player)
	if not save then return 0 end

	local map = save.Index :: any
	if type(map) ~= "table" then return 0 end
	
	local count = 0
	for fishId, entry in pairs(map) do
		if entry and entry.Galaxy == true then
			count += 1
		end
	end
	return count
end

--[[
	Gets the total count of fish species that have been caught with Spooky mutation.
	
	@param player - The player to check
	@return number - Count of fish species with Spooky variant caught
]]
function Index.GetSpookyCount(player: Player): number
	local save = Saving.Get(player)
	if not save then return 0 end

	local map = save.Index :: any
	if type(map) ~= "table" then return 0 end
	
	local count = 0
	for fishId, entry in pairs(map) do
		if entry and entry.Spooky == true then
			count += 1
		end
	end
	return count
end

return Index


