--!strict

return {
	DisplayName = "Money Leaderboard",
	Description = "Most money!",
	DisplayAmount = 100,
    IsDollar = true,
	ScoreGetter = function(player: Player)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local plot = ServerPlot.GetByPlayer(player)
		return plot and plot:GetMoney() or 0
	end,
}