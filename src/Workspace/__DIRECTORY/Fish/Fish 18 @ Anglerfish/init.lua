--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Anglerfish",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 85,
    BaseUpgradeCost = 108000,
    BillboardOffset = 7,
    RarityWeight = 30,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir



