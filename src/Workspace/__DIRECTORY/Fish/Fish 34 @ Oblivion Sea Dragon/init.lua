--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Oblivion Sea Dragon",
    Icon = "rbxassetid://105441199491812",
    MutationIcons = {
        Bloodfish = "rbxassetid://109557521648928",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 950,
    BaseUpgradeCost = 30000,
    BillboardOffset = 12,
    PedestalOffset = -2,
    RarityWeight = 2,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



