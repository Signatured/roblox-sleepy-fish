--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Catfish",
    Icon = "rbxassetid://102726042572452",
    Rarity = Rarity.Common,
    MoneyPerSecond = 3,
    BaseUpgradeCost = 70,
    BillboardOffset = 5.5,
    RarityWeight = 15,
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
}::FishTypes.raw_dir



