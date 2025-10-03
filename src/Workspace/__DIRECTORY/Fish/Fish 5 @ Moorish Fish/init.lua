--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Moorish Fish",
    Icon = "rbxassetid://119872940972353",
    MutationIcons = {
        Bloodfish = "rbxassetid://120058448869410",
        Galaxy = "rbxassetid://105804792308514",
    },
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 6,
    BaseUpgradeCost = 100,
    BillboardOffset = 7,
    RarityWeight = 30,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-0.5, -0.5, 0),
}::FishTypes.raw_dir



