--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sockeye Salmon",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 4,
    BaseUpgradeCost = 120,
    BillboardOffset = 6,
}::FishTypes.raw_dir



