--!strict

local Players = game:GetService("Players")
local Icon = require(game.ReplicatedStorage.Game.Modules.Icon)
local TabController = require(game.ReplicatedStorage.Library.Client.TabController)
local Network = require(game.ReplicatedStorage.Library.Client.Network)
local Save = require(game.ReplicatedStorage.Library.Client.Save)
local ProductCmds = require(game.ReplicatedStorage.Library.Client.ProductCmds)
local Marketplace = require(game.ReplicatedStorage.Library.Marketplace)
local FFlags = require(game.ReplicatedStorage.Library.Client.FFlags)

local localPlayer = Players.LocalPlayer

task.spawn(function()
    while true do
        local save = Save.Get()
        if not save or not save.TutorialClaim then
            task.wait(1)
            continue
        end
        
        Icon.new()
            :setImage("rbxassetid://79796798608289")
            :setLabel("Quests")
            :oneClick(true)
            .selected:Connect(function()
                if TabController.GetCurrentTab() == "DailyQuests" then
                    TabController.CloseTab()
                else
                    TabController.OpenTab("DailyQuests")
                    Network.Fire("DailyQuestButton")
                end
            end)

        Icon.new()
            :setLabel("Admin")
            :oneClick(true)
            .selected:Connect(function()
                if ProductCmds.Owns("Admin Panel") or FFlags.Get(FFlags.Keys.FreeAdminPanel) then
                    print("open panel")
                else
                    local product = ProductCmds.GetProductId("Admin Panel")
                    if not product then return end
                    Marketplace.Prompt(localPlayer, product, true)
                end
            end)

            break
    end
end)