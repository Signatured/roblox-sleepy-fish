--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Swordfish",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 28,
    BaseUpgradeCost = 6000,
    BillboardOffset = 7,
    RarityWeight = 10,
}::FishTypes.raw_dir



