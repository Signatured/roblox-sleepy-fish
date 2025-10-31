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
    BillboardOffset = 13,
    PedestalOffset = -1,
    RarityWeight = 10,
    IndexOffset = -6,
    IndexPositionOffset = Vector3.new(0, 0, 0),
    IndexRotationOffset = Vector3.new(math.rad(90), 0, math.rad(-90)),
}::FishTypes.raw_dir




