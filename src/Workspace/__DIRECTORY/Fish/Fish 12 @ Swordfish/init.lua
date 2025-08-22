--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Swordfish",
    Icon = "rbxassetid://121200626306150",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 28,
    BaseUpgradeCost = 6000,
    BillboardOffset = 7,
    RarityWeight = 10,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
}::FishTypes.raw_dir



