--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Octobloop",
    Icon = "rbxassetid://114385688262048",
    MutationIcons = {
        Bloodfish = "rbxassetid://79007910712218",
        Galaxy = "rbxassetid://101923213586939",
        Spooky = "rbxassetid://101142318868075",
        Haunted = "rbxassetid://129478307940153",
        YinYang = "rbxassetid://134745312940063",
    },
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 150,
    BaseUpgradeCost = 10000,
    BillboardOffset = 11,
    PedestalOffset = -2,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
    BestFishMultiplier = 2,
}::FishTypes.raw_dir



