--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Puffer Fish",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 24,
    BaseUpgradeCost = 3690,
    BillboardOffset = 6.5,
    RarityWeight = 20,
}::FishTypes.raw_dir



