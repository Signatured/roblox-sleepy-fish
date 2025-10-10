--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "God",
    Rarity = Rarity.God,
    Loot = {
        ["Crowned Anglerfish"] = 40,
        ["Vortex Barracuda"] = 30,
        ["Squalana"] = 20,
        ["Loch Ness Monster"] = 10,
    },
}::LuckyBlockTypes.raw_dir
