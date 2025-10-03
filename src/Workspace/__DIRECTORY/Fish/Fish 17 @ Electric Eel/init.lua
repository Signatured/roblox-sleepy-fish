--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Electric Eel",
    Icon = "rbxassetid://81816650499286",
    MutationIcons = {
        Bloodfish = "rbxassetid://94030853150359",
        Galaxy = "",
    },
    Rarity = Rarity.Epic,
    MoneyPerSecond = 50,
    BaseUpgradeCost = 1000,
    BillboardOffset = 5.5,
    RarityWeight = 15,
    IndexOffset = 4,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



