--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Skeleton Seahorse",
    Icon = "rbxassetid://121124709133867",
    MutationIcons = {
        Bloodfish = "rbxassetid://119628112879305",
        Galaxy = "rbxassetid://78831121890972",
        Spooky = "rbxassetid://126697480873290",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 95,
    BaseUpgradeCost = 2000,
    BillboardOffset = 9.5,
    PedestalOffset = 2,
    RarityWeight = 14,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.5, -1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



