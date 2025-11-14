--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Hammerhead Shark",
    Icon = "rbxassetid://89376900524787",
    MutationIcons = {
        Bloodfish = "rbxassetid://76588129208543",
        Galaxy = "rbxassetid://138688307281403",
        Spooky = "rbxassetid://104002404270238",
        Haunted = "rbxassetid://137828458776868",
        YinYang = "rbxassetid://131670943824978",
    },
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 10,
    BaseUpgradeCost = 160,
    BillboardOffset = 7,
    RarityWeight = 15,
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    IndexOffset = 2,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
}::FishTypes.raw_dir



