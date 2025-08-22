--!strict

return {
	DisplayName = "Time Leaderboard",
	Description = "Most time played!",
	DisplayAmount = 100,
    IsTime = true,
	ScoreGetter = function(player: Player)
		local Saving = require(game.ServerScriptService.Library.Saving)
		local save = Saving.Get(player)
		return save and save.Playtime or 0
	end,
}