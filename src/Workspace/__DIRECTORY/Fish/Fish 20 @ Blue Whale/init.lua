--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Blue Whale",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 9447,
    BaseUpgradeCost = 283410,
    BillboardOffset = 7,
}::FishTypes.raw_dir



