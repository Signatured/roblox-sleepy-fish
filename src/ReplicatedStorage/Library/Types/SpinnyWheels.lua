--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)

local module = {}

export type Reward = {
    Index: number,
	Weight: number,
	DisplayChance: string,
	Icon: string,
	Title1: string?,
	Title2: string?,
	Title3: string?,
	AltText: string?,
}

export type raw_dir = {
	DisplayName: string,
	Description: string,
	Cost: number,
	Rewards: {Reward},
	GiveReward: (player: Player, reward: Reward) -> (),
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module 