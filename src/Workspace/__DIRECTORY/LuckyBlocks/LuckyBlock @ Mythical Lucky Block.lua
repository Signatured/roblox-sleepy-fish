--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical",
    Rarity = Rarity.Mythical,
    Loot = {
        ["Giant Jellyfish"] = 100,
        ["Blobfish"] = 50,
        ["Graipuss Medussi"] = 25,
        ["Megalodon Shark"] = 25,
        ["Crystalite Fish"] = 25,
        ["Firevulcan Serpent"] = 25,
        ["Narwhal"] = 25,
        ["Diamond Serpent"] = 25,
    },
}::LuckyBlockTypes.raw_dir
