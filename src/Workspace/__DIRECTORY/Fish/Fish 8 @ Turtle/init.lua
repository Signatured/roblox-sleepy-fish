--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Turtle",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 29,
    BaseUpgradeCost = 870,
    BillboardOffset = 7,
}::FishTypes.raw_dir



