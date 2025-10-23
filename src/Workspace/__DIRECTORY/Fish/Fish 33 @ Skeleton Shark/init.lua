--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Skeleton Shark",
    Icon = "rbxassetid://115237634632337",
    MutationIcons = {
        Bloodfish = "rbxassetid://124452443817591",
        Galaxy = "rbxassetid://126875872610697",
        Spooky = "rbxassetid://125161516395414",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 900,
    BaseUpgradeCost = 26000,
    BillboardOffset = 12,
    PedestalOffset = -2,
    RarityWeight = 12,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-9, -1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



