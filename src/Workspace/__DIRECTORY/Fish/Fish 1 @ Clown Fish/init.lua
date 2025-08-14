--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Clown Fish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 1,
    BaseUpgradeCost = 30,
    BillboardOffset = 5,
}::FishTypes.raw_dir



