--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Trulimero Trulichina",
    Rarity = Rarity.Common,
    MoneyPerSecond = 4,
    BaseUpgradeCost = 120
}::FishTypes.raw_dir


