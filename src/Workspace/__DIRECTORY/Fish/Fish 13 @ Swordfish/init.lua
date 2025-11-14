--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Swordfish",
    Icon = "rbxassetid://88458071940200",
    MutationIcons = {
        Bloodfish = "rbxassetid://75817866442955",
        Galaxy = "rbxassetid://120568685411425",
        Spooky = "rbxassetid://136165490892372",
        Haunted = "rbxassetid://103930811469112",
        YinYang = "rbxassetid://114314770215623",
    },
    Rarity = Rarity.Rare,
    MoneyPerSecond = 28,
    BaseUpgradeCost = 450,
    BillboardOffset = 7,
    RarityWeight = 10,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-1, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



