--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Megalodon Shark",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 250,
    BaseUpgradeCost = 1207980,
    BillboardOffset = 7,
    RarityWeight = 20,
}::FishTypes.raw_dir



