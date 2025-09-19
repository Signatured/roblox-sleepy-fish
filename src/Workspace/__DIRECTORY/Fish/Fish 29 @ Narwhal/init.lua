--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Narwhal",
    Icon = "rbxassetid://90100794789269",
    MutationIcons = {
        Bloodfish = "rbxassetid://137872727279052",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 450,
    BaseUpgradeCost = 11000,
    BillboardOffset = 7,
    PedestalOffset = -0.5,
    RarityWeight = 1,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
}::FishTypes.raw_dir



