--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Whale Shark",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 100,
    BaseUpgradeCost = 174960,
    BillboardOffset = 6,
    RarityWeight = 20,
}::FishTypes.raw_dir



