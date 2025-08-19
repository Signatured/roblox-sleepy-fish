--!strict

return {
	ProductId = 3375973460,
	DisplayName = "[OP] 2x Server Luck!",
	Icon = "",
	Description = "Activate 2x server luck!",
	OneTimePurchase = false,
	ClientTest = function(player: Player)
		local ServerLuckCmds = require(game.ReplicatedStorage.Game.Library.Client.ServerLuckCmds)

		return ServerLuckCmds.GetMultiplier() == 1
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerLuck = require(game.ServerScriptService.Game.Library.ServerLuck)

		return ServerLuck.GetServerLuck() == 1
	end,
	Callback = function(player: Player): (boolean, string?)
		local ServerLuck = require(game.ServerScriptService.Game.Library.ServerLuck)

		local currentMultiplier = ServerLuck.GetServerLuck()

		if currentMultiplier ~= 1 then
			return false, "This server already has 2x server luck!"
		end

		ServerLuck.Activate2xLuck()

		return true
	end,
}