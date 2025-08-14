--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Directory)

local module = {}

export type raw_dir = {
    DisplayName: string,
    Color: Color3,
    Priority: number,
    RarityWeight: number
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module


