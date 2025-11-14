--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Nightmare Maja",
    Icon = "rbxassetid://82803321939240",
    MutationIcons = {
        Bloodfish = "rbxassetid://93368172717234",
        Galaxy = "rbxassetid://126624016705908",
        Spooky = "rbxassetid://77237730484469",
        Haunted = "rbxassetid://136056820728649",
        YinYang = "",
    },
    Rarity = Rarity.Exclusive,
    MoneyPerSecond = 150,
    BaseUpgradeCost = 10000,
    BillboardOffset = 11,
    PedestalOffset = -4,
    RarityWeight = 0,
    -- IndexOffset = 8,
    -- IndexPositionOffset = Vector3.new(-7, 2, 0),
    BestFishMultiplier = 2,
}::FishTypes.raw_dir



