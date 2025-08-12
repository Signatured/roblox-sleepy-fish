--!strict

local PlotTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Plots)

--[[
	Defines the default stats for a new player.
	This is the master schema for all player data.
]]

export type schema = {
	PlotSave: PlotTypes.Save,
	Money: number,
}

local DefaultStats = {
	PlotSave = {
		Variables = {
			Pedestals = 1
		},
	},
	Money = 0,
}::schema

return DefaultStats
