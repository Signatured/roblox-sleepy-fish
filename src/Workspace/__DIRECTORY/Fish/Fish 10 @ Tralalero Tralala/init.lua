--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Tralalero Tralala",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 20,
    BaseUpgradeCost = 2280,
    BillboardOffset = 7,
    RarityWeight = 30,
}::FishTypes.raw_dir



