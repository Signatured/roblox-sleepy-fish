--!strict

local Icon = require(game.ReplicatedStorage.Game.Modules.Icon)
local TabController = require(game.ReplicatedStorage.Library.Client.TabController)
local Network = require(game.ReplicatedStorage.Library.Client.Network)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

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

            break
    end
end)