--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Bombardino Crocodilo",
    Rarity = Rarity.Common,
    MoneyPerSecond = 200,
    BaseUpgradeCost = 6000,
    BillboardOffset = 7,
}::FishTypes.raw_dir



