--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Haunted Kraken",
    Icon = "rbxassetid://126180884467474",
    MutationIcons = {
        Bloodfish = "rbxassetid://139741143103598",
        Galaxy = "rbxassetid://122205135305488",
        Spooky = "rbxassetid://112584389800656",
        Haunted = "rbxassetid://116588442444865",
        YinYang = "",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 640,
    BaseUpgradeCost = 14750,
    BillboardOffset = 13,
    PedestalOffset = -1,
    RarityWeight = 0,
    IndexOffset = -6,
    IndexPositionOffset = Vector3.new(0, 0, 0),
    IndexRotationOffset = Vector3.new(math.rad(90), 0, math.rad(-90)),
    DisableSpawn = true,
}::FishTypes.raw_dir




