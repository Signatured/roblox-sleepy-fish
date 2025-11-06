--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Rave Turtle",
    Icon = "rbxassetid://70545770243718",
    MutationIcons = {
        Bloodfish = "rbxassetid://70545770243718",
        Galaxy = "rbxassetid://70545770243718",
        Spooky = "rbxassetid://70545770243718",
        Haunted = "rbxassetid://70545770243718",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 170,
    BaseUpgradeCost = 3800,
    BillboardOffset = 7,
    RarityWeight = 24.5,
    IndexRotationOffset = Vector3.new(0, math.rad(-180), 0),
    IndexOffset = 1.5,
    IndexPositionOffset = Vector3.new(0, 0.2, 0),
}::FishTypes.raw_dir



