--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Kraken",
    Icon = "rbxassetid://112137818479760",
    MutationIcons = {
        Bloodfish = "rbxassetid://112137818479760",
        Galaxy = "rbxassetid://112137818479760",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 640,
    BaseUpgradeCost = 14750,
    BillboardOffset = 8,
    PedestalOffset = -1,
    RarityWeight = 5,
    IndexOffset = 2,
    IndexPositionOffset = Vector3.new(-4, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir




