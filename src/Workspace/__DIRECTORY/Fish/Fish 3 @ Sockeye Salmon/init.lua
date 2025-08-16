--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sockeye Salmon",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 3,
    BaseUpgradeCost = 90,
    BillboardOffset = 7,
}::FishTypes.raw_dir



