--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Common Pumpkin",
    Icon = "rbxassetid://82908039985513",
    Rarity = Rarity.Common,
    MoneyPerSecond = 0,
    BaseUpgradeCost = 0,
    BillboardOffset = 6.5,
    RarityWeight = 0,
    SpecialItemFish = true,
    OverrideSellPrice = 10_000,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



