--!strict

return {
	ProductId = 3406886872,
	DisplayName = "[OP] Buy 3 Wheel Spins!",
	Icon = "rbxassetid://109838009828589",
	Description = "Buy 1 Wheel Spin!",
	OneTimePurchase = false,
	ClientTest = function(player: Player)
		local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
		local Save = require(game.ReplicatedStorage.Library.Client.Save)

		local plot = ClientPlot.GetLocal()
		local save = Save.Get()
		return plot ~= nil and save ~= nil
	end,
	ServerTest = function(player: Player): (boolean, string?)
		local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
		local Saving = require(game.ServerScriptService.Library.Saving)

		local plot = ServerPlot.GetByPlayer(player)
		if not plot then
			return false, "No plot found!"
		end

		local save = Saving.Get(player)
		if not save then
			return false, "No save found!"
		end

		return true
	end,
	Callback = function(player: Player): (boolean, string?)
		local Notifications = require(game.ServerScriptService.Library.Notifications)
		local Saving = require(game.ServerScriptService.Library.Saving)

		local save = Saving.Get(player)
		if not save then
			return false, "No save found!"
		end

		-- Grant 1 paid spin for the wheel (id derived from module name)
		local wheelId = "Spooky"
		save.Wheels = save.Wheels or {}
		save.Wheels[wheelId] = save.Wheels[wheelId] or { Free = 0, Paid = 0, FreeNextAt = nil }
		save.Wheels[wheelId].Paid += 3

		Notifications.Message(player, `You purchased 3 Spooky Wheel Spins!`, {
			Time = 6,
			Color = Color3.fromRGB(255, 128, 43)
		})

		return true
	end,
}