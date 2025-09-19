--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Carp",
    Icon = "rbxassetid://136220631178988",
    MutationIcons = {
        Bloodfish = "rbxassetid://138769929232166",
    },
    Rarity = Rarity.Common,
    MoneyPerSecond = 2,
    BaseUpgradeCost = 60,
    BillboardOffset = 5.5,
    RarityWeight = 15,
    IndexOffset = 2,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
}::FishTypes.raw_dir



