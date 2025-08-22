--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Blobfish",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 200,
    BaseUpgradeCost = 744750,
    BillboardOffset = 6,
    RarityWeight = 25,
    IndexRotationOffset = Vector3.new(0, math.rad(-70), 0),
    IndexOffset = 0.5,
    IndexPositionOffset = Vector3.new(0.5, -0.2, 0),
}::FishTypes.raw_dir



