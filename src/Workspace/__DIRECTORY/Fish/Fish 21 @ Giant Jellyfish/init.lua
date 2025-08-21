--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Giant Jellyfish",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 170,
    BaseUpgradeCost = 459300,
    BillboardOffset = 7,
    RarityWeight = 40,
}::FishTypes.raw_dir



