--!strict

local PlotTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Plots)

--[[
	Defines the default stats for a new player.
	This is the master schema for all player data.
]]

export type PlotSave = {
	Pedestals: number,
	PedestalData: PedestalData
}

export type PedestalData = {[string]: {
	Level: number,
}}

export type schema = {
	PlotSave: {
		Variables: PlotSave,
	},
	Money: number,
}

local DefaultStats = {
	PlotSave = {
		Variables = {
			Pedestals = 1,
			PedestalData = {}
		},
	},
	Money = 0,
}::schema

return DefaultStats
