--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Firefly Squid",
    Icon = "rbxassetid://126732776258447",
    MutationIcons = {
        Bloodfish = "rbxassetid://99131114797726",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 700,
    BaseUpgradeCost = 18000,
    BillboardOffset = 13,
    -- PedestalOffset = -2.5,
    RarityWeight = 45,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



