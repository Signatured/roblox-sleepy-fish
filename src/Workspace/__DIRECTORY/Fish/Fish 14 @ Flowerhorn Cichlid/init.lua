--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Flowerhorn Cichlid",
    Icon = "rbxassetid://106319261870683",
    MutationIcons = {
        Bloodfish = "rbxassetid://81754143710062",
    },
    Rarity = Rarity.Epic,
    MoneyPerSecond = 32,
    BaseUpgradeCost = 550,
    BillboardOffset = 6,
    RarityWeight = 30,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



