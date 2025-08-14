--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Le Anglerfish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 15310,
    BaseUpgradeCost = 459300,
    BillboardOffset = 7,
}::FishTypes.raw_dir



