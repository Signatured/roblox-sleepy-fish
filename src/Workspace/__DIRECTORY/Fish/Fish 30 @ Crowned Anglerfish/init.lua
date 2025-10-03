--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Crowned Anglerfish",
    Icon = "rbxassetid://95559005677854",
    MutationIcons = {
        Bloodfish = "rbxassetid://95559005677854",
        Galaxy = "",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 600,
    BaseUpgradeCost = 13000,
    BillboardOffset = 11,
    PedestalOffset = -2,
    RarityWeight = 60,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir




