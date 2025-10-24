--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Skeleton Seahorse",
    Icon = "rbxassetid://88747837083551",
    MutationIcons = {
        Bloodfish = "rbxassetid://124111484915158",
        Galaxy = "rbxassetid://124086688296135",
        Spooky = "rbxassetid://138933764153134",
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



