--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "God",
    Rarity = Rarity.God,
    Loot = {
        ["Squalana"] = 40,
        ["Midnight Barracuda"] = 30,
        ["Loch Ness Monster"] = 20,
        ["Bladewave Hammerhead"] = 10,
    },
}::LuckyBlockTypes.raw_dir
