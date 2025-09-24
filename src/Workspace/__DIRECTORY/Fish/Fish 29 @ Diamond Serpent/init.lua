--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Diamond Serpent",
    Icon = "rbxassetid://0",
    MutationIcons = {
        Bloodfish = "rbxassetid://0",
    },
    Rarity = Rarity.Mythical,
    -- Better than Narwhal (450), below Firefly Squid (700)
    MoneyPerSecond = 520,
    BaseUpgradeCost = 12500,
    BillboardOffset = 9,
    PedestalOffset = -2.5,
    -- Slightly rarer than Narwhal (1) following mythical scaling (lower weight = rarer)
    RarityWeight = 0.8,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
}::FishTypes.raw_dir




