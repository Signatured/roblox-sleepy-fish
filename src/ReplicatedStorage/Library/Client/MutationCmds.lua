--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local MutationTypes = require(ReplicatedStorage.Game.Library.Types.Mutations)

local MutationCmds = {}

--[[
    Gets the earnings multiplier for a fish based on its mutation.
    Returns 1 if no mutation or mutation not found.
    
    @param fishData - The fish data containing mutation information
    @return number - The earnings multiplier
]]
function MutationCmds.GetMutationMulti(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): number
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
function MutationCmds.HasMutation(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema, mutationId: string): boolean
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
function MutationCmds.GetMutationData(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): MutationTypes.dir_schema?
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
function MutationCmds.GetMutationDisplayName(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): string?
    local mutationData = MutationCmds.GetMutationData(fishData)
    return mutationData and mutationData.DisplayName or nil
end

--[[
    Gets the color associated with a fish's mutation.
    Returns nil if no mutation.
    
    @param fishData - The fish data containing mutation information
    @return Color3? - The mutation color
]]
function MutationCmds.GetMutationColor(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): Color3?
    local mutationData = MutationCmds.GetMutationData(fishData)
    return mutationData and mutationData.Color or nil
end

--[[
    Formats the mutation display for UI elements.
    Returns formatted string with color if mutation exists.
    
    @param fishData - The fish data containing mutation information
    @return string - Formatted mutation text or empty string
]]
function MutationCmds.FormatMutationDisplay(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): string
    local mutationData = MutationCmds.GetMutationData(fishData)
    if not mutationData then
        return ""
    end
    
    local color = mutationData.Color
    local hexColor = string.format("#%02X%02X%02X", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255))
    
    return `<font color="{hexColor}">{mutationData.DisplayName}</font>`
end

return MutationCmds