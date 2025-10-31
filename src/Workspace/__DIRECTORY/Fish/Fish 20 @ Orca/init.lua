--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Orca",
    Icon = "rbxassetid://80571201044562",
    MutationIcons = {
        Bloodfish = "rbxassetid://82330284782781",
        Galaxy = "rbxassetid://79045354757208",
        Spooky = "rbxassetid://131701582458993",
        Haunted = "rbxassetid://124499261743478",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 90,
    BaseUpgradeCost = 1900,
    BillboardOffset = 7,
    PedestalOffset = -3.5,
    RarityWeight = 16,
    IndexOffset = 6,
    IndexPositionOffset = Vector3.new(-3, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(160), 0),
}::FishTypes.raw_dir



