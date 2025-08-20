--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Catfish",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 3,
    BaseUpgradeCost = 90,
    BillboardOffset = 5.5,
}::FishTypes.raw_dir



