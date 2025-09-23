--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Luminite Shark",
    Icon = "rbxassetid://91872405889650",
    MutationIcons = {
        Bloodfish = "rbxassetid://87655859693533",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 800,
    BaseUpgradeCost = 22500,
    BillboardOffset = 12,
    PedestalOffset = -2.5,
    RarityWeight = 15,
    IndexOffset = 7,
    IndexPositionOffset = Vector3.new(-7, -1, 0),
}::FishTypes.raw_dir



