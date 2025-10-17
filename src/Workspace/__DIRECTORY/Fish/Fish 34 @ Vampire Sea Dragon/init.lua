--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Vampire Sea Dragon",
    Icon = "rbxassetid://136331765901242",
    MutationIcons = {
        Bloodfish = "rbxassetid://136331765901242",
        Galaxy = "rbxassetid://136331765901242",
        Spooky = "",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 960,
    BaseUpgradeCost = 30500,
    BillboardOffset = 12,
    PedestalOffset = -4,
    RarityWeight = 5,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



