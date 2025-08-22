--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Moorish Fish",
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 6,
    BaseUpgradeCost = 210,
    BillboardOffset = 7,
    RarityWeight = 40,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-0.5, -0.5, 0),
}::FishTypes.raw_dir



