--!strict

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local TabController = require(game.ReplicatedStorage.Library.Client.TabController)

local Satchel = require(game.ReplicatedStorage.Game.Modules.Satchel)

RunService.RenderStepped:Connect(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    print(TabController.GetCurrentTab() ~= "SpinnyWheel", TabController.GetCurrentTab())
    Satchel:SetBackpackEnabled(TabController.GetCurrentTab() ~= "SpinnyWheel")
end)