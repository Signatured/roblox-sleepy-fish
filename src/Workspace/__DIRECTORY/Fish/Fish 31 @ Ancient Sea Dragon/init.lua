--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Ancient Sea Dragon",
    Icon = "rbxassetid://124358989249012",
    MutationIcons = {
        Bloodfish = "rbxassetid://124358989249012",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 825,
    BaseUpgradeCost = 22000,
    BillboardOffset = 9,
    PedestalOffset = -2.5,
    RarityWeight = 30,
    -- IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



