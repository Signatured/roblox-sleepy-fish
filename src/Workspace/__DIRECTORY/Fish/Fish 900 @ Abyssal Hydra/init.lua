--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Abyssal Hydra",
    Icon = "rbxassetid://111872157833540",
    MutationIcons = {
        Bloodfish = "rbxassetid://140518545722406",
        Galaxy = "rbxassetid://140576448604664",
        Spooky = "rbxassetid://120679516900650",
        Haunted = "rbxassetid://76151802823043",
    },
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 150,
    BaseUpgradeCost = 10000,
    BillboardOffset = 18.5,
    PedestalOffset = -6,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
    BestFishMultiplier = 1.5,
}::FishTypes.raw_dir



