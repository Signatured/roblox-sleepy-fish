--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Graipuss Medussi",
    Icon = "rbxassetid://93541654161971",
    MutationIcons = {
        Bloodfish = "rbxassetid://128048198317470",
        Galaxy = "rbxassetid://129297039420612",
        Spooky = "rbxassetid://99787847627718",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 225,
    BaseUpgradeCost = 5800,
    BillboardOffset = 10,
    PedestalOffset = -0.5,
    RarityWeight = 12,
    IndexRotationOffset = Vector3.new(0, math.rad(-90), 0),
    -- IndexOffset = 0.5,
    -- IndexPositionOffset = Vector3.new(0.5, -0.2, 0),
}::FishTypes.raw_dir



