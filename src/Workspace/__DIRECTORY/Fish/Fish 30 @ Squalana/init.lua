--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Squalana",
    Icon = "rbxassetid://121363521821478",
    MutationIcons = {
        Bloodfish = "rbxassetid://105175484754660",
        Galaxy = "rbxassetid://107011493534643",
        Spooky = "rbxassetid://127936959988740",
        Haunted = "rbxassetid://110455967819048",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 635,
    BaseUpgradeCost = 14500,
    BillboardOffset = 8,
    PedestalOffset = -1,
    RarityWeight = 10,
    IndexOffset = 2,
    IndexPositionOffset = Vector3.new(-4, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir




