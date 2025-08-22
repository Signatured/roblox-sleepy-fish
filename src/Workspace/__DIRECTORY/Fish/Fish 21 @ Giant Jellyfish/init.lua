--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Giant Jellyfish",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 170,
    BaseUpgradeCost = 459300,
    BillboardOffset = 7,
    RarityWeight = 40,
    IndexRotationOffset = Vector3.new(0, math.rad(-70), 0),
    IndexOffset = 1.5,
    IndexPositionOffset = Vector3.new(0, 0.2, 0),
}::FishTypes.raw_dir



