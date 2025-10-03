--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Dory",
    Icon = "rbxassetid://86023134773124",
    MutationIcons = {
        Bloodfish = "rbxassetid://137007646333787",
        Galaxy = "",
    },
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 7,
    BaseUpgradeCost = 120,
    BillboardOffset = 6,
    RarityWeight = 25,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-0.5, -0.5, 0),
}::FishTypes.raw_dir



