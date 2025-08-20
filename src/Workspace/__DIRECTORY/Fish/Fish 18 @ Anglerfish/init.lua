--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Anglerfish",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 3600,
    BaseUpgradeCost = 108000,
    BillboardOffset = 7,
}::FishTypes.raw_dir



