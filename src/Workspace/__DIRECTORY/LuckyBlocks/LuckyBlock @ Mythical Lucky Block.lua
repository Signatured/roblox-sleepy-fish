--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical",
    Rarity = Rarity.Mythical,
    Loot = {
        ["Haunted Prawn"] = 40,
        ["Candy Corn Shark"] = 30,
        ["Narwhal"] = 20,
        ["Diamond Serpent"] = 10,
    },
}::LuckyBlockTypes.raw_dir
