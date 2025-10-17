--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Kraken",
    Icon = "rbxassetid://126180884467474",
    MutationIcons = {
        Bloodfish = "rbxassetid://126180884467474",
        Galaxy = "rbxassetid://126180884467474",
        Spooky = "",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 640,
    BaseUpgradeCost = 14750,
    BillboardOffset = 13,
    PedestalOffset = -1,
    RarityWeight = 5,
    IndexOffset = -6,
    IndexPositionOffset = Vector3.new(0, 0, 0),
    IndexRotationOffset = Vector3.new(math.rad(90), 0, math.rad(-90)),
}::FishTypes.raw_dir




