--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sea Turtle",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 47,
    BaseUpgradeCost = 1410,
    BillboardOffset = 5.5,
}::FishTypes.raw_dir



