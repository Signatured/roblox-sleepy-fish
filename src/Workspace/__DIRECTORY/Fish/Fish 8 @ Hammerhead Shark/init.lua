--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Hammerhead Shark",
    Icon = "rbxassetid://89376900524787",
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 10,
    BaseUpgradeCost = 160,
    BillboardOffset = 7,
    RarityWeight = 15,
    IndexRotationOffset = Vector3.new(0, math.rad(-90), 0),
    IndexOffset = -3.5,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
}::FishTypes.raw_dir



