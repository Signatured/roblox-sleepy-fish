--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Clown Fish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 1,
    BaseUpgradeCost = 30,
    BillboardOffset = 7,
}::FishTypes.raw_dir



