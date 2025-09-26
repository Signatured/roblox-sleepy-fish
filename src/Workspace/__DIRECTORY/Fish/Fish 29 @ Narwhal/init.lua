--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Narwhal",
    Icon = "rbxassetid://115727958930970",
    MutationIcons = {
        Bloodfish = "rbxassetid://101793152935431",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 450,
    BaseUpgradeCost = 11000,
    BillboardOffset = 7,
    PedestalOffset = -0.5,
    RarityWeight = 1,
    IndexOffset = -23,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



