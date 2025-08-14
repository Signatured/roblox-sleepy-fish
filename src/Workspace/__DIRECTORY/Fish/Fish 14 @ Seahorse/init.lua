--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Seahorse",
    Rarity = Rarity.Common,
    MoneyPerSecond = 524,
    BaseUpgradeCost = 15720,
    BillboardOffset = 7,
}::FishTypes.raw_dir



