--!strict

local RunService = game:GetService("RunService")

local WAIT_TIME = RunService:IsStudio() and 30 or 99999999
local PlayerGui: typeof(game.StarterGui) = game.Players.LocalPlayer:WaitForChild("PlayerGui", WAIT_TIME)

local module = {}

function module.Notifications() return PlayerGui:WaitForChild("Notifications", WAIT_TIME) end

return module
