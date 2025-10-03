--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Imperium Whale",
    Icon = "rbxassetid://99968950359680",
    MutationIcons = {
        Bloodfish = "rbxassetid://124483285860707",
        Galaxy = "rbxassetid://79709413745812",
    },
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 150,
    BaseUpgradeCost = 10000,
    BillboardOffset = 13,
    PedestalOffset = -3,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
    BestFishMultiplier = 2,
}::FishTypes.raw_dir



