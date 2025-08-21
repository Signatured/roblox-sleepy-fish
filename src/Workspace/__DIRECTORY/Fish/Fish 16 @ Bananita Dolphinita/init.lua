--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Bananita Dolphinita",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 60,
    BaseUpgradeCost = 41190,
    BillboardOffset = 7,
    RarityWeight = 10,
}::FishTypes.raw_dir



