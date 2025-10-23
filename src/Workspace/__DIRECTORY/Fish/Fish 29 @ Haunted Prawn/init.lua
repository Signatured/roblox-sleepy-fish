--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Prawn",
    Icon = "rbxassetid://115727958930970",
    MutationIcons = {
        Bloodfish = "rbxassetid://101793152935431",
        Galaxy = "rbxassetid://76270915645237",
        Spooky = "rbxassetid://75427686974919",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 430,
    BaseUpgradeCost = 10650,
    BillboardOffset = 7,
    PedestalOffset = -0.5,
    RarityWeight = 3,
    IndexOffset = -23,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



