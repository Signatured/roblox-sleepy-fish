--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Carp",
    Rarity = Rarity.Common,
    MoneyPerSecond = 2,
    BaseUpgradeCost = 60,
    BillboardOffset = 5.5,
    RarityWeight = 15,
}::FishTypes.raw_dir



