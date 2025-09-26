--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Diamond Serpent",
    Icon = "rbxassetid://0",
    MutationIcons = {
        Bloodfish = "rbxassetid://0",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 475,
    BaseUpgradeCost = 11500,
    BillboardOffset = 9,
    PedestalOffset = -2.5,
    RarityWeight = 0.5,
    IndexOffset = -12,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir




