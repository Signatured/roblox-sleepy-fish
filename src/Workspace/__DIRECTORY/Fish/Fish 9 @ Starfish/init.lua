--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Starfish",
    Icon = "rbxassetid://134483109412863",
    MutationIcons = {
        Bloodfish = "rbxassetid://124042147674222",
        Galaxy = "rbxassetid://126810820836324",
        Spooky = "",
    },
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 12,
    BaseUpgradeCost = 200,
    BillboardOffset = 7,
    RarityWeight = 10,
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    IndexPositionOffset = Vector3.new(0.5, 0, 0),
}::FishTypes.raw_dir



