--!strict

-- Periodically checks all online players' inventory and pedestal fish
-- and ensures they are properly indexed. This fixes cases where players
-- have fish but somehow never got them logged in their index.

local Players = game:GetService("Players")

local Index = require(game.ServerScriptService.Game.Library.Index)
local Saving = require(game.ServerScriptService.Library.Saving)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local PlotTypes = require(game.ReplicatedStorage.Game.Library.Types.Plots)

local PATCH_INTERVAL = 5 -- seconds

local function IsFishIndexed(indexMap: any, fishId: string, fishType: FishTypes.fish_type, mutation: FishTypes.fish_mutation_type?): boolean
	if type(indexMap) ~= "table" then
		return false
	end
	
	local entry = indexMap[fishId]
	if not entry or type(entry) ~= "table" then
		return false
	end
	
	-- Check if the specific variant is indexed
	local variantIndexed = false
	if fishType == "Normal" then
		variantIndexed = entry.Normal == true
	elseif fishType == "Shiny" then
		variantIndexed = entry.Shiny == true
	elseif fishType == "Gold" then
		variantIndexed = entry.Gold == true
	elseif fishType == "Rainbow" then
		variantIndexed = entry.Rainbow == true
	end
	
	-- Check if the mutation is indexed (if applicable)
	local mutationIndexed = true
	if mutation == "Bloodfish" then
		mutationIndexed = entry.BloodMoon == true
	elseif mutation == "Galaxy" then
		mutationIndexed = entry.Galaxy == true
	end
	
	return variantIndexed and mutationIndexed
end

local function PatchPlayerIndex(player: Player)
	local save = Saving.Get(player)
	if not save then
		return
	end
	
	local indexMap = save.Index
	local patchedCount = 0
	
	-- Check inventory fish
	local inventory = save.Inventory :: {FishTypes.data_schema}
	if type(inventory) == "table" then
		for _, fishData in ipairs(inventory) do
			if fishData and fishData.FishId and fishData.Type then
				if not IsFishIndexed(indexMap, fishData.FishId, fishData.Type, fishData.Mutation) then
					Index.Add(player, fishData.FishId, fishData.Type, fishData.Mutation)
					patchedCount += 1
				end
			end
		end
	end
	
	-- Check pedestal fish
	local plotSave = save.PlotSave
	if type(plotSave) == "table" then
		local variables = plotSave.Variables
		if type(variables) == "table" then
			local pedestalFish = variables.Fish :: {[string]: PlotTypes.Fish}
			if type(pedestalFish) == "table" then
				for _, pedestalData in pairs(pedestalFish) do
					if pedestalData and pedestalData.FishData then
						local fishData = pedestalData.FishData
						if fishData.FishId and fishData.Type then
							if not IsFishIndexed(indexMap, fishData.FishId, fishData.Type, fishData.Mutation) then
								Index.Add(player, fishData.FishId, fishData.Type, fishData.Mutation)
								patchedCount += 1
							end
						end
					end
				end
			end
		end
	end
	
	if patchedCount > 0 then
		print(`[IndexPatch] Patched {patchedCount} fish for {player.Name}`)
	end
end

-- Main patch loop
task.spawn(function()
	while true do
		task.wait(PATCH_INTERVAL)

        print("looped")
		
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				local success = pcall(PatchPlayerIndex, player)
				if not success then
					warn(`[IndexPatch] Error patching {player.Name}`)
				end
			end)
		end
	end
end)

print("[IndexPatch] Index patch system started - checking every", PATCH_INTERVAL, "seconds")

