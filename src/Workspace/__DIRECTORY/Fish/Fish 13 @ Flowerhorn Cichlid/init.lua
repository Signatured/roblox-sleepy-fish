--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Flowerhorn Cichlid",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 32,
    BaseUpgradeCost = 9720,
    BillboardOffset = 6,
    RarityWeight = 40,
}::FishTypes.raw_dir



