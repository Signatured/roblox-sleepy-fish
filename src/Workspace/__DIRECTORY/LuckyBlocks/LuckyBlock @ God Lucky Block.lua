--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "God",
    Rarity = Rarity.God,
    Loot = {
        ["Crowned Anglerfish"] = 60,
        ["Loch Ness Monster"] = 30,
        ["Vortex Barracuda"] = 10,
    },
}::LuckyBlockTypes.raw_dir
