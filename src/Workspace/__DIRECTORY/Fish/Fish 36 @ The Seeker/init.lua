--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "The Seeker",
    Icon = "rbxassetid://89658188700696",
    MutationIcons = {
        Bloodfish = "rbxassetid://112183688935106",
        Galaxy = "rbxassetid://80968908078731",
        Spooky = "rbxassetid://102950632185989",
        Haunted = "rbxassetid://84352568262413",
        YinYang = "",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 1050,
    BaseUpgradeCost = 34000,
    BillboardOffset = 13,
    PedestalOffset = -2,
    RarityWeight = 1,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



