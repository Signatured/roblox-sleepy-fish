--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Whale Shark",
    Icon = "rbxassetid://126935022978658",
    MutationIcons = {
        Bloodfish = "rbxassetid://94590884977629",
        Galaxy = "rbxassetid://80920312388869",
        Spooky = "rbxassetid://93741543187470",
        Haunted = "rbxassetid://108933069492673",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 100,
    BaseUpgradeCost = 2100,
    BillboardOffset = 6,
    RarityWeight = 15,
    IndexOffset = 1.5,
    IndexPositionOffset = Vector3.new(-4, 0, 0),
}::FishTypes.raw_dir



