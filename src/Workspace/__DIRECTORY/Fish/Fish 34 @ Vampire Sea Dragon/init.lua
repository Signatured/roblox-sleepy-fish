--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Vampire Sea Dragon",
    Icon = "rbxassetid://136331765901242",
    MutationIcons = {
        Bloodfish = "rbxassetid://136331765901242",
        Galaxy = "rbxassetid://136331765901242",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 960,
    BaseUpgradeCost = 30500,
    BillboardOffset = 12,
    PedestalOffset = -2,
    RarityWeight = 5,
    -- IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



