--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Bananita Dolphinita",
    Rarity = Rarity.Common,
    MoneyPerSecond = 76,
    BaseUpgradeCost = 2280,
    BillboardOffset = 7,
}::FishTypes.raw_dir



