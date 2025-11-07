--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Midnight Barracuda",
    Icon = "rbxassetid://139219899406336",
    MutationIcons = {
        Bloodfish = "rbxassetid://103471540600476",
        Galaxy = "rbxassetid://108553347560347",
        Spooky = "rbxassetid://109387190617621",
        Haunted = "rbxassetid://115157309877910",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 640,
    BaseUpgradeCost = 14750,
    BillboardOffset = 12,
    PedestalOffset = -7,
    RarityWeight = 5,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
}::FishTypes.raw_dir




