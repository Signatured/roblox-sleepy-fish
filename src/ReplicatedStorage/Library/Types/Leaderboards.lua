--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)

local module = {}

export type raw_dir = {
	DisplayName: string,
	Description: string,
	ScoreGetter: (player: Player) -> (number),
	DisplayAmount: number?,
    IsDollar: boolean?,
    IsTime: boolean?,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module


