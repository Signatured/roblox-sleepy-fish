--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Zombie Tralalero",
    Icon = "rbxassetid://106296036649881",
    MutationIcons = {
        Bloodfish = "rbxassetid://106296036649881",
        Galaxy = "rbxassetid://106296036649881",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 425,
    BaseUpgradeCost = 10500,
    BillboardOffset = 9,
    PedestalOffset = -2.5,
    RarityWeight = 3,
    IndexOffset = 8,
    IndexPositionOffset = Vector3.new(-5, 2, 0),
}::FishTypes.raw_dir



