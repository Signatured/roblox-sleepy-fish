--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local MutationTypes = require(ReplicatedStorage.Game.Library.Types.Mutations)

local Mutations = {}

--[[
    Gets the earnings multiplier for a fish based on its mutation.
    Returns 1 if no mutation or mutation not found.
    
    @param fishData - The fish data containing mutation information
    @return number - The earnings multiplier
]]
function Mutations.GetMutationMulti(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): number
    -- Handle swimming fish schema
    local actualFishData: FishTypes.data_schema
    if (fishData :: any).FishData then
        actualFishData = (fishData :: FishTypes.swimming_fish_schema).FishData
    else
        actualFishData = fishData :: FishTypes.data_schema
    end
    
    -- Check if fish has a mutation
    if not actualFishData.Mutation then
        return 1
    end
    
    -- Look up mutation in directory
    local mutationData = Directory.Mutations[actualFishData.Mutation]
    if not mutationData then
        warn("Unknown mutation:", actualFishData.Mutation)
        return 1
    end
    
    -- Return the multiplier, defaulting to 1 if not specified
    return mutationData.MutationEarningsMultiplier or 1
end

--[[
    Checks if a fish has a specific mutation.
    
    @param fishData - The fish data to check
    @param mutationId - The mutation ID to check for
    @return boolean - Whether the fish has the specified mutation
]]
function Mutations.HasMutation(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema, mutationId: string): boolean
    -- Handle swimming fish schema
    local actualFishData: FishTypes.data_schema
    if (fishData :: any).FishData then
        actualFishData = (fishData :: FishTypes.swimming_fish_schema).FishData
    else
        actualFishData = fishData :: FishTypes.data_schema
    end
    
    return actualFishData.Mutation == mutationId
end

--[[
    Gets the mutation data for a fish.
    Returns nil if no mutation or mutation not found.
    
    @param fishData - The fish data containing mutation information
    @return MutationTypes.dir_schema? - The mutation directory data
]]
function Mutations.GetMutationData(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): MutationTypes.dir_schema?
    -- Handle swimming fish schema
    local actualFishData: FishTypes.data_schema
    if (fishData :: any).FishData then
        actualFishData = (fishData :: FishTypes.swimming_fish_schema).FishData
    else
        actualFishData = fishData :: FishTypes.data_schema
    end
    
    if not actualFishData.Mutation then
        return nil
    end
    
    return Directory.Mutations[actualFishData.Mutation]
end

--[[
    Gets the display name of a fish's mutation.
    Returns nil if no mutation.
    
    @param fishData - The fish data containing mutation information
    @return string? - The mutation display name
]]
function Mutations.GetMutationDisplayName(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): string?
    local mutationData = Mutations.GetMutationData(fishData)
    return mutationData and mutationData.DisplayName or nil
end

--[[
    Gets the color associated with a fish's mutation.
    Returns nil if no mutation.
    
    @param fishData - The fish data containing mutation information
    @return Color3? - The mutation color
]]
function Mutations.GetMutationColor(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): Color3?
    local mutationData = Mutations.GetMutationData(fishData)
    return mutationData and mutationData.Color or nil
end

return Mutations