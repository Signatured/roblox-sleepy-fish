--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Pumpkin Puffer",
    Icon = "rbxassetid://137862564036884",
    MutationIcons = {
        Bloodfish = "rbxassetid://137862564036884",
        Galaxy = "rbxassetid://137862564036884",
        Spooky = "",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 95,
    BaseUpgradeCost = 2000,
    BillboardOffset = 9.5,
    PedestalOffset = 0,
    RarityWeight = 15,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.5, -1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



