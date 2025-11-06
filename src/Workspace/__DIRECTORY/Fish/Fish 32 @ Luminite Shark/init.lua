--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Luminite Shark",
    Icon = "rbxassetid://91872405889650",
    MutationIcons = {
        Bloodfish = "rbxassetid://87655859693533",
        Galaxy = "rbxassetid://118682327596657",
        Spooky = "rbxassetid://101471518597610",
        Haunted = "rbxassetid://132681485782502",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 850,
    BaseUpgradeCost = 24000,
    BillboardOffset = 12,
    PedestalOffset = -2.5,
    RarityWeight = 13,
    IndexOffset = 7,
    IndexPositionOffset = Vector3.new(-7, -1, 0),
}::FishTypes.raw_dir



