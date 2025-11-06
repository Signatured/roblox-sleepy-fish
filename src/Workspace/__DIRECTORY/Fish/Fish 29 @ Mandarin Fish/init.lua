--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mandarin Fish", 
    Icon = "rbxassetid://97593230164895",
    MutationIcons = {
        Bloodfish = "rbxassetid://97593230164895",
        Galaxy = "rbxassetid://97593230164895",
        Spooky = "rbxassetid://97593230164895",
        Haunted = "rbxassetid://97593230164895",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 425,
    BaseUpgradeCost = 10500,
    BillboardOffset = 10,
    PedestalOffset = 0.5,
    RarityWeight = 8,
    IndexOffset = -4,
    IndexPositionOffset = Vector3.new(-3, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



