--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Serpent",
    Icon = "rbxassetid://126720375076900",
    MutationIcons = {
        Bloodfish = "rbxassetid://91657947060140",
        Galaxy = "rbxassetid://110004498070196",
        Spooky = "rbxassetid://94055399095481",
        Haunted = "rbxassetid://134763674643025",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 637,
    BaseUpgradeCost = 14600,
    BillboardOffset = 12,
    PedestalOffset = -7,
    RarityWeight = 0,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
    DisableSpawn = true,
}::FishTypes.raw_dir




