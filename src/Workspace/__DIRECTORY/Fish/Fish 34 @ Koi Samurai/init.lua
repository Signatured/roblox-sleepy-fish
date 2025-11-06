--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

warn("setup koi samurai")
return {
    DisplayName = "Koi Samurai",
    Icon = "rbxassetid://136331765901242",
    MutationIcons = {
        Bloodfish = "rbxassetid://79099792473267",
        Galaxy = "rbxassetid://96162368252642",
        Spooky = "rbxassetid://90798913903995",
        Haunted = "rbxassetid://128254235226856",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 960,
    BaseUpgradeCost = 30500,
    BillboardOffset = 12,
    PedestalOffset = -4,
    RarityWeight = 8,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



