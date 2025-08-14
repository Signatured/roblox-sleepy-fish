--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Starfish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 7,
    BaseUpgradeCost = 210,
    BillboardOffset = 7,
}::FishTypes.raw_dir



