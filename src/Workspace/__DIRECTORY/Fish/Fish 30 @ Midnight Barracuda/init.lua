--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Midnight Barracuda",
    Icon = "rbxassetid://139219899406336",
    MutationIcons = {
        Bloodfish = "rbxassetid://139219899406336",
        Galaxy = "rbxassetid://139219899406336",
        Spooky = "rbxassetid://139219899406336",
        Haunted = "rbxassetid://139219899406336",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 637,
    BaseUpgradeCost = 14600,
    BillboardOffset = 12,
    PedestalOffset = -7,
    RarityWeight = 10,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
}::FishTypes.raw_dir




