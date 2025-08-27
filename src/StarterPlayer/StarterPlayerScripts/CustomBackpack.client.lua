--!strict

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Satchel = require(game.ReplicatedStorage.Game.Modules.Satchel)

RunService.RenderStepped:Connect(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)