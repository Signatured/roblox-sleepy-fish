--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Trippi Troppi",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 11,
    BaseUpgradeCost = 330,
    BillboardOffset = 7,
}::FishTypes.raw_dir



