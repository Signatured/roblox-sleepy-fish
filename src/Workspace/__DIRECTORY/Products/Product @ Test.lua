--!strict

local RunService = game:GetService("RunService")

return {
	ProductId = 3354009677,
	DisplayName = "Fish the dish",
	Icon = "",
	Description = "Test",
	OneTimePurchase = false,
	Callback = function(player: Player)
		-- local Saving = require(game.ServerScriptService.Library.Saving)

		-- local save = Saving.Get(player)
		-- if not save then
		-- 	return false
		-- end

		-- save.Coins += 75_000
		return true
	end,
}