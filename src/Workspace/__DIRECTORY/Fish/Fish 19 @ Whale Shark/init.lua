--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Whale Shark",
    Rarity = Rarity.Common,
    MoneyPerSecond = 5832,
    BaseUpgradeCost = 174960,
    BillboardOffset = 7,
}::FishTypes.raw_dir



