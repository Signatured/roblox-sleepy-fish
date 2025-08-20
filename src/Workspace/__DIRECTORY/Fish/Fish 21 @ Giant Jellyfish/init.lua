--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Le Anglerfish",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 15310,
    BaseUpgradeCost = 459300,
    BillboardOffset = 7,
}::FishTypes.raw_dir



