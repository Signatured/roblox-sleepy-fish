--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Crystaldeath Fish",
    Rarity = Rarity.Secret,
    MoneyPerSecond = 40266,
    BaseUpgradeCost = 1207980,
    BillboardOffset = 7,
}::FishTypes.raw_dir



