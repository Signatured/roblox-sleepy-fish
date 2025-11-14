--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Pumpkin Puffer",
    Icon = "rbxassetid://121124709133867",
    MutationIcons = {
        Bloodfish = "rbxassetid://119628112879305",
        Galaxy = "rbxassetid://78831121890972",
        Spooky = "rbxassetid://126697480873290",
        Haunted = "rbxassetid://89531562635833",
        YinYang = "rbxassetid://104707899340847",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 95,
    BaseUpgradeCost = 2000,
    BillboardOffset = 9.5,
    PedestalOffset = 0,
    RarityWeight = 0,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.5, -1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    DisableSpawn = true,
}::FishTypes.raw_dir



