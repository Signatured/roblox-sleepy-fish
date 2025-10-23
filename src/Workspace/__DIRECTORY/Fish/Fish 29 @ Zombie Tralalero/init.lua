--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Zombie Tralalero", 
    Icon = "rbxassetid://106296036649881",
    MutationIcons = {
        Bloodfish = "rbxassetid://96529139558594",
        Galaxy = "rbxassetid://78486715760654",
        Spooky = "rbxassetid://115425984195493",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 425,
    BaseUpgradeCost = 10500,
    BillboardOffset = 10,
    PedestalOffset = 0.5,
    RarityWeight = 5,
    IndexOffset = -4,
    IndexPositionOffset = Vector3.new(-3, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



