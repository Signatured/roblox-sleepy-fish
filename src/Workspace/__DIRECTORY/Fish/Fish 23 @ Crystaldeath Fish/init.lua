--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Crystaldeath Fish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 40266,
    BaseUpgradeCost = 1207980,
    BillboardOffset = 7,
}::FishTypes.raw_dir



