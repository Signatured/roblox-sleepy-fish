--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Prawn",
    Icon = "rbxassetid://74932174099576",
    MutationIcons = {
        Bloodfish = "rbxassetid://131432108467604",
        Galaxy = "rbxassetid://131885109502242",
        Spooky = "rbxassetid://74921609506668",
        Haunted = "rbxassetid://119298087093111",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 430,
    BaseUpgradeCost = 10650,
    BillboardOffset = 7,
    PedestalOffset = -0.5,
    RarityWeight = 5,
    IndexOffset = -23,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



