--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Serpent",
    Icon = "rbxassetid://126720375076900",
    MutationIcons = {
        Bloodfish = "rbxassetid://126720375076900",
        Galaxy = "rbxassetid://126720375076900",
        Spooky = "rbxassetid://126720375076900",
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




