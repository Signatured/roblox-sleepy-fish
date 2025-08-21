--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sea Turtle",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 15,
    BaseUpgradeCost = 1410,
    BillboardOffset = 5.5,
    RarityWeight = 40,
}::FishTypes.raw_dir



