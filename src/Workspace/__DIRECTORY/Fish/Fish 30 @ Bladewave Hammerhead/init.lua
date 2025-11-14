--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Bladewave Hammerhead",
    Icon = "rbxassetid://116074728091223",
    MutationIcons = {
        Bloodfish = "rbxassetid://105580869414645",
        Galaxy = "rbxassetid://71870876623444",
        Spooky = "rbxassetid://79358742609324",
        Haunted = "rbxassetid://137289804819411",
        YinYang = "rbxassetid://85257947158723",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 675,
    BaseUpgradeCost = 15500,
    BillboardOffset = 10,
    PedestalOffset = 0,
    RarityWeight = 1,
    IndexOffset = -12,
    IndexPositionOffset = Vector3.new(-5, 1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir




