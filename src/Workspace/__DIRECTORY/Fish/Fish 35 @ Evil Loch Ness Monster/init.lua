--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Evil Loch Ness Monster",
    Icon = "rbxassetid://70416191994449",
    MutationIcons = {
        Bloodfish = "rbxassetid://132484094867459",
        Galaxy = "rbxassetid://107173792145881",
        Spooky = "rbxassetid://135541451000695",
        Haunted = "rbxassetid://102444887889439",
        YinYang = "",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 980,
    BaseUpgradeCost = 32250,
    BillboardOffset = 13,
    PedestalOffset = -4.5,
    RarityWeight = 0,
    IndexOffset = -12,
    IndexPositionOffset = Vector3.new(-5, 1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
    DisableSpawn = true,
}::FishTypes.raw_dir



