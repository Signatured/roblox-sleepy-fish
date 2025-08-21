--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Blue Whale",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 120,
    BaseUpgradeCost = 283410,
    BillboardOffset = 6.5,
    RarityWeight = 10,
}::FishTypes.raw_dir



