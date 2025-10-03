--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Tralalero Tralala",
    Icon = "rbxassetid://78493277717365",
    MutationIcons = {
        Bloodfish = "rbxassetid://91126765413074",
        Galaxy = "",
    },
    Rarity = Rarity.Rare,
    MoneyPerSecond = 20,
    BaseUpgradeCost = 300,
    BillboardOffset = 7,
    RarityWeight = 30,
    IndexOffset = 1.5,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



