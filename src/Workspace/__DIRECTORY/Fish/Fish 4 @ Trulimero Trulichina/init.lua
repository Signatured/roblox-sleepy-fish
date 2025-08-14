--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Trulimero Trulichina",
    Rarity = Rarity.Common,
    MoneyPerSecond = 4,
    BaseUpgradeCost = 120,
    BillboardOffset = 7,
}::FishTypes.raw_dir



