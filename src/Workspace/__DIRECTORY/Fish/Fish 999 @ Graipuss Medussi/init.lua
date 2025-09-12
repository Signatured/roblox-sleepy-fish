--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Graipuss Medussi",
    Icon = "rbxassetid://93541654161971",
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 50,
    BaseUpgradeCost = 10000,
    BillboardOffset = 13,
    PedestalOffset = -2,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



