--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Candy Corn Shark",
    Icon = "rbxassetid://78218642922148",
    MutationIcons = {
        Bloodfish = "rbxassetid://106221867066090",
        Galaxy = "rbxassetid://127913741982579",
        Spooky = "rbxassetid://125983515057452",
        Haunted = "rbxassetid://70590873282444",
        YinYang = "rbxassetid://98111537245450",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 440,
    BaseUpgradeCost = 10750,
    BillboardOffset = 7,
    RarityWeight = 0,
    IndexOffset = 0,
    IndexPositionOffset = Vector3.new(-4.5, -0.5, 0),
    DisableSpawn = true,
}::FishTypes.raw_dir



