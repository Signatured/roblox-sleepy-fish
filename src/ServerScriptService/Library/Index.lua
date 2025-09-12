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
}

local Index = {}

local function ensureEntry(map: {[string]: IndexData}, fishId: string): IndexData
	local entry = map[fishId]
	if not entry then
		entry = { Normal = false, Shiny = false, Gold = false, Rainbow = false }
		map[fishId] = entry
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

function Index.Add(player: Player, fishId: string, fishType: FishTypes.fish_type)
	local save = Saving.Get(player)
	if not save then return end

	local map = save.Index :: {[string]: IndexData}
	local entry = ensureEntry(map, fishId)
	markVariant(entry, fishType)
end

local function entryComplete(entry: IndexData?): boolean
	if not entry then return false end
	return entry.Normal == true and entry.Shiny == true and entry.Gold == true and entry.Rainbow == true
end

function Index.IsCompleted(player: Player): boolean
	local save = Saving.Get(player)
	if not save then return false end

	local map = save.Index :: {[string]: IndexData}
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

return Index


