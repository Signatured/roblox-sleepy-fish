--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Vortex Barracuda",
    Icon = "rbxassetid://74379222733109",
    MutationIcons = {
        Bloodfish = "rbxassetid://129758208612200",
        Galaxy = "rbxassetid://80752607042430",
        Spooky = "",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 625,
    BaseUpgradeCost = 14000,
    BillboardOffset = 9,
    PedestalOffset = -1,
    RarityWeight = 30,
    IndexOffset = -12,
    IndexPositionOffset = Vector3.new(-5, -1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir




