--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Zombie Tralalero",
    Icon = "rbxassetid://90100794789269",
    MutationIcons = {
        Bloodfish = "rbxassetid://137872727279052",
        Galaxy = "rbxassetid://113374408263385",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 425,
    BaseUpgradeCost = 10500,
    BillboardOffset = 9,
    PedestalOffset = -2.5,
    RarityWeight = 3,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
}::FishTypes.raw_dir



