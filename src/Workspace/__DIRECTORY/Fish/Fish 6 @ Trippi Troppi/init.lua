--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Trippi Troppi",
    Rarity = Rarity.Common,
    MoneyPerSecond = 11,
    BaseUpgradeCost = 330,
    BillboardOffset = 7,
}::FishTypes.raw_dir



