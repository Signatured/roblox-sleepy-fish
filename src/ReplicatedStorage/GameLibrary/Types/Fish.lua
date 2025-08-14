--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Directory)
local RarityTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Rarity)

local module = {}

export type raw_dir = {
    DisplayName: string,
    Rarity: RarityTypes.dir_schema,
    MoneyPerSecond: number,
    BaseUpgradeCost: number,
    BillboardOffset: number,
}

export type data_schema = {
    UID: string,
    FishId: string,
    Type: "Normal" | "Shiny" | "Gold" | "Rainbow",
    Shiny: boolean?,
    Level: number,
    CreateTime: number,
    BaseTime: number,
}

export type create_params = {
    FishId: string,
    Type: "Normal" | "Shiny" | "Gold" | "Rainbow",
    Shiny: boolean?,
    Level: number?,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module
