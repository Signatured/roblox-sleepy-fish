--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Trippi Troppi",
    Icon = "rbxassetid://97131944980291",
    MutationIcons = {
        Bloodfish = "rbxassetid://107338509611274",
    },
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 8,
    BaseUpgradeCost = 140,
    BillboardOffset = 7,
    RarityWeight = 20,
    IndexRotationOffset = Vector3.new(0, math.rad(-90), 0),
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
}::FishTypes.raw_dir



