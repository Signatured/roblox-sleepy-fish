--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical Lucky Block",
    Icon = "rbxassetid://113173438319438",
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 0,
    BaseUpgradeCost = 0,
    BillboardOffset = 6.5,
    RarityWeight = 0,
    LuckyBlockId = "Mythical Lucky Block",
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
}::FishTypes.raw_dir



