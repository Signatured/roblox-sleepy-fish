--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Trippi Troppi",
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 8,
    BaseUpgradeCost = 330,
    BillboardOffset = 7,
    RarityWeight = 30,
}::FishTypes.raw_dir



