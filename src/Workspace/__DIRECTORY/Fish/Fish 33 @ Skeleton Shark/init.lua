--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Skeleton Shark",
    Icon = "rbxassetid://91872405889650",
    MutationIcons = {
        Bloodfish = "rbxassetid://87655859693533",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 800,
    BaseUpgradeCost = 22500,
    BillboardOffset = 12,
    PedestalOffset = -2.5,
    RarityWeight = 5,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



