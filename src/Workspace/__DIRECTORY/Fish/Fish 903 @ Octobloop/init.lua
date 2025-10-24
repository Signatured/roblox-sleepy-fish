--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Octobloop",
    Icon = "rbxassetid://114385688262048",
    MutationIcons = {
        Bloodfish = "rbxassetid://114385688262048",
        Galaxy = "rbxassetid://114385688262048",
        Spooky = "rbxassetid://114385688262048",
    },
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 150,
    BaseUpgradeCost = 10000,
    BillboardOffset = 11,
    PedestalOffset = -4,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
    BestFishMultiplier = 2,
}::FishTypes.raw_dir



