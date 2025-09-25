--!strict

return {
	ProductId = 3414068106,
	DisplayName = "[SAFE] Lock Base (1 Hour)",
	Icon = "rbxassetid://0",
	Description = "Lock base for 1 hour!",
	OneTimePurchase = false,
	ClientTest = function(player: Player): (boolean, string?)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

		local plot = ClientPlot.GetLocal()
		if not plot then
			return false, "No plot found!"
		end

		local lockTime = plot:Save("LockTime")::number?
		if lockTime and lockTime > workspace:GetServerTimeNow() then
			return false, "Base is already locked!"
		end

		return true
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local lockTime = plot:Save("LockTime")::number?
		if lockTime and lockTime > workspace:GetServerTimeNow() then
			return false, "Base is already locked!"
		end

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local Notifications = require(game.ServerScriptService.Library.Notifications)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local lockTime = plot:Save("LockTime")::number?
		if lockTime and lockTime > workspace:GetServerTimeNow() then
			return false, "Base is already locked!"
		end

		plot:SaveSet("LockTime", workspace:GetServerTimeNow() + (60 * 60))

		Notifications.Message(player, `You locked your base for 1 hour!`, {
			Time = 6,
			Color = Color3.fromRGB(0, 255, 0)
		})

		return true
	end,
}