--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Blobfish",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 2223,
    BaseUpgradeCost = 66690,
    BillboardOffset = 7,
}::FishTypes.raw_dir



