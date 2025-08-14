--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Flowerhorn Cichlid",
    Rarity = Rarity.Common,
    MoneyPerSecond = 324,
    BaseUpgradeCost = 9720,
    BillboardOffset = 7,
}::FishTypes.raw_dir



