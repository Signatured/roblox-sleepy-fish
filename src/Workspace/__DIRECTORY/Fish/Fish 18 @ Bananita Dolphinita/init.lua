--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Bananita Dolphinita",
    Icon = "rbxassetid://78770060981693",
    MutationIcons = {
        Bloodfish = "rbxassetid://98402809539072",
        Galaxy = "rbxassetid://118583611627226",
    },
    Rarity = Rarity.Epic,
    MoneyPerSecond = 60,
    BaseUpgradeCost = 1200,
    BillboardOffset = 7,
    RarityWeight = 10,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.25, 0.25, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



