--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "God",
    Rarity = Rarity.God,
    Loot = {
        ["Crystalite Fish"] = 55,
        ["Firevulcan Serpent"] = 30,
        ["Narwhal"] = 10,
        ["Diamond Serpent"] = 5,
    },
}::LuckyBlockTypes.raw_dir
