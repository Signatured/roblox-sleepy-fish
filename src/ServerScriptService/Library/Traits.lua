--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local TraitTypes = require(ReplicatedStorage.Game.Library.Types.Traits)

local Traits = {}

--[[
    Gets the total earnings multiplier for a fish based on all its traits.
    Returns 1 if no traits or traits not found.
    
    @param fishData - The fish data containing trait information
    @return number - The combined earnings multiplier
]]
function Traits.GetTraitMulti(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): number
    -- Handle swimming fish schema
    local actualFishData: FishTypes.data_schema
    if (fishData :: any).FishData then
        actualFishData = (fishData :: FishTypes.swimming_fish_schema).FishData
    else
        actualFishData = fishData :: FishTypes.data_schema
    end
    
    -- Check if fish has traits
    if not actualFishData.Traits then
        return 1
    end
    
    local totalMultiplier = 1
    
    -- Multiply all trait multipliers together
    for traitId, hasTrait in pairs(actualFishData.Traits) do
        if hasTrait then
            local traitData = Directory.Traits[traitId]
            if traitData then
                totalMultiplier = totalMultiplier * (traitData.TraitEarningsMultiplier or 1)
            else
                warn("Unknown trait:", traitId)
            end
        end
    end
    
    return totalMultiplier
end

--[[
    Checks if a fish has a specific trait.
    
    @param fishData - The fish data to check
    @param traitId - The trait ID to check for
    @return boolean - Whether the fish has the specified trait
]]
function Traits.HasTrait(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema, traitId: string): boolean
    -- Handle swimming fish schema
    local actualFishData: FishTypes.data_schema
    if (fishData :: any).FishData then
        actualFishData = (fishData :: FishTypes.swimming_fish_schema).FishData
    else
        actualFishData = fishData :: FishTypes.data_schema
    end
    
    return actualFishData.Traits and actualFishData.Traits[traitId] == true or false
end

--[[
    Gets all trait data for a fish.
    Returns an empty table if no traits.
    
    @param fishData - The fish data containing trait information
    @return {TraitTypes.dir_schema} - Array of trait directory data
]]
function Traits.GetTraitData(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema): {TraitTypes.dir_schema}
    -- Handle swimming fish schema
    local actualFishData: FishTypes.data_schema
    if (fishData :: any).FishData then
        actualFishData = (fishData :: FishTypes.swimming_fish_schema).FishData
    else
        actualFishData = fishData :: FishTypes.data_schema
    end
    
    local traits: {TraitTypes.dir_schema} = {}
    
    if not actualFishData.Traits then
        return traits
    end
    
    for traitId, hasTrait in pairs(actualFishData.Traits) do
        if hasTrait then
            local traitData = Directory.Traits[traitId]
            if traitData then
                table.insert(traits, traitData)
            end
        end
    end
    
    return traits
end

--[[
    Applies all trait effects to a fish model.
    
    @param fishData - The fish data containing trait information
    @param model - The fish model to apply traits to
]]
function Traits.ApplyTraitsToModel(fishData: FishTypes.data_schema | FishTypes.swimming_fish_schema, model: Model)
    local traits = Traits.GetTraitData(fishData)
    
    for _, traitData in ipairs(traits) do
        if traitData.ApplyToModel then
            traitData.ApplyToModel(model)
        end
    end
end

--[[
    Gets a specific trait's data by ID.
    Returns nil if trait not found.
    
    @param traitId - The trait ID to look up
    @return TraitTypes.dir_schema? - The trait directory data
]]
function Traits.GetTraitById(traitId: string): TraitTypes.dir_schema?
    return Directory.Traits[traitId]
end

return Traits










