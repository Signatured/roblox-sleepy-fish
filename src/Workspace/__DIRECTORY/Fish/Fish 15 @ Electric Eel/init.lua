--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Electric Eel",
    Icon = "rbxassetid://86024252567320",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 50,
    BaseUpgradeCost = 25440,
    BillboardOffset = 5.5,
    RarityWeight = 20,
    IndexOffset = 4,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
}::FishTypes.raw_dir



