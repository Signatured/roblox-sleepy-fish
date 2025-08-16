--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "King Jellyfish",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 24825,
    BaseUpgradeCost = 744750,
    BillboardOffset = 7,
}::FishTypes.raw_dir



