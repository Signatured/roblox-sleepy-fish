--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "The Blood Moon",
    Icon = "rbxassetid://93529278578197",
    MutationIcons = {
        Bloodfish = "rbxassetid://88885264918338",
        Galaxy = "rbxassetid://84060503232998",
        Spooky = "rbxassetid://84825299102953",
        Haunted = "rbxassetid://125088221847067",
    },
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 150,
    BaseUpgradeCost = 10000,
    BillboardOffset = 11,
    PedestalOffset = -2,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
    BestFishMultiplier = 2,
}::FishTypes.raw_dir



