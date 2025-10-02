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
    MoneyPerSecond = 800,
    BaseUpgradeCost = 20500,
    BillboardOffset = 13,
    -- PedestalOffset = -2.5,
    RarityWeight = 43,
    IndexOffset = -10,
    IndexPositionOffset = Vector3.new(0, 2, 0),
    IndexRotationOffset = Vector3.new(math.rad(-90), 0, math.rad(90)),
}::FishTypes.raw_dir



