--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Crowned Anglerfish",
    Icon = "rbxassetid://95559005677854",
    MutationIcons = {
        Bloodfish = "rbxassetid://95546461857691",
        Galaxy = "rbxassetid://85373590369130",
        Spooky = "rbxassetid://87382378062401",
        Haunted = "rbxassetid://85774134701270",
        YinYang = "rbxassetid://91347225906624",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 600,
    BaseUpgradeCost = 13000,
    BillboardOffset = 11,
    PedestalOffset = -2,
    RarityWeight = 39,
    IndexOffset = -8,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir




