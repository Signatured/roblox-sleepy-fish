--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Crystalite Fish",
    Icon = "rbxassetid://129164143486030",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 350,
    BaseUpgradeCost = 8500,
    BillboardOffset = 6,
    RarityWeight = 10,
    -- IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    IndexOffset = 2,
    IndexPositionOffset = Vector3.new(-3, 0, 0),
}::FishTypes.raw_dir



