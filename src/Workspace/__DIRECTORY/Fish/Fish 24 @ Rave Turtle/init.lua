--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Rave Turtle",
    Icon = "rbxassetid://74298369722425",
    MutationIcons = {
        Bloodfish = "rbxassetid://138465378317929",
        Galaxy = "rbxassetid://97469201117682",
        Spooky = "rbxassetid://86894127565074",
        Haunted = "rbxassetid://114483417764665",
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



