--!strict

--[[
	Manages player leaderboards.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPlot = require(ServerScriptService.Plot.ServerPlot)

local function onPlayerAdded(player: Player)
	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money 💸"
	money.Value = 0 -- Default to 0
	money.Parent = leaderstats

	-- Initialize with saved data
	local plot = ServerPlot.GetByPlayer(player)
	if plot then
		money.Value = plot:GetMoney()
	end
end

ServerPlot.Created:Connect(function(plot: ServerPlot.Type)
	onPlayerAdded(plot:GetOwner())
end)

-- Periodically check for updates to the Wins stat
task.spawn(function()
	while task.wait(1) do
		for _, player in ipairs(Players:GetPlayers()) do
			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats then
				continue
			end

			local moneyStat = leaderstats:FindFirstChild("Money 💸")
			if not (moneyStat and moneyStat:IsA("IntValue")) then
				continue
			end

			local plot = ServerPlot.GetByPlayer(player)
			if plot then
				if moneyStat.Value ~= plot:GetMoney() then
					moneyStat.Value = plot:GetMoney()
				end
			end
		end
	end
end) 