--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Catfish",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 2,
    BaseUpgradeCost = 60,
    BillboardOffset = 7,
}::FishTypes.raw_dir



