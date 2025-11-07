--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Rave Turtle",
    Icon = "rbxassetid://70545770243718",
    MutationIcons = {
        Bloodfish = "rbxassetid://71314109493002",
        Galaxy = "rbxassetid://135354630691432",
        Spooky = "rbxassetid://93971329314506",
        Haunted = "rbxassetid://84948444852225",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 235,
    BaseUpgradeCost = 6000,
    BillboardOffset = 9,
    RarityWeight = 12,
    IndexRotationOffset = Vector3.new(0, math.rad(-180), 0),
    IndexOffset = 1.5,
    IndexPositionOffset = Vector3.new(0, 0.2, 0),
}::FishTypes.raw_dir



