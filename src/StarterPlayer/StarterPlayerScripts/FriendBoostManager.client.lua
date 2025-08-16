--!strict

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local GUI = require(game.ReplicatedStorage.Game.Library.Client.GUI)

local main = GUI.Main()
local bottomLeft = main:WaitForChild("BottomLeft")
local desc = bottomLeft:WaitForChild("Desc")
local friendBoostText = desc:WaitForChild("FriendBoost")::TextLabel

local function updateFriendBoost(plot: ClientPlot.Type)
    local friendBoost = plot:Session("FriendBoost") or 0
    friendBoostText.Text = `Friend Boost: +{friendBoost}%`
end

print("this happens")
ClientPlot.GetOrWaitLocal(function(plot)
    if not plot:IsLocal() then 
        return
    end

    updateFriendBoost(plot)

    plot:SessionChanged("FriendBoost"):Connect(function(value: number)
        updateFriendBoost(plot)
    end)
end)