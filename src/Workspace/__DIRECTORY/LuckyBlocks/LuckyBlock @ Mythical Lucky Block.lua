--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical",
    Rarity = Rarity.Mythical,
    Loot = {
        ["Firevulcan Serpent"] = 40,
        ["Zombie Tralalero"] = 30,
        ["Narwhal"] = 20,
        ["Diamond Serpent"] = 10,
    },
}::LuckyBlockTypes.raw_dir
