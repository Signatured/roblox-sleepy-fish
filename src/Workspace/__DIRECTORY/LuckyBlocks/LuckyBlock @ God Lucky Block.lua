--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "God",
    Rarity = Rarity.God,
    Loot = {
        ["Vortex Barracuda"] = 40,
        ["Squalana"] = 30,
        ["Haunted Kraken"] = 20,
        ["Loch Ness Monster"] = 10,
    },
}::LuckyBlockTypes.raw_dir
