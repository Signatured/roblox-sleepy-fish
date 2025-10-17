--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Pumpkin Puffer",
    Icon = "rbxassetid://80571201044562",
    MutationIcons = {
        Bloodfish = "rbxassetid://82330284782781",
        Galaxy = "rbxassetid://79045354757208",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 95,
    BaseUpgradeCost = 2000,
    BillboardOffset = 7,
    PedestalOffset = -3.5,
    RarityWeight = 15,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



