--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Firevulcan Serpent",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 400,
    BaseUpgradeCost = 3000000,
    BillboardOffset = 9,
    PedestalOffset = -2.5,
    RarityWeight = 5,
}::FishTypes.raw_dir



