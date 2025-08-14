--!strict

local Assets = game.ReplicatedStorage.Assets

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local Functions = require(game.ReplicatedStorage.Library.Functions)

Network.Fired("AlertPart", function(position: Vector3, radius: number)
    local alertPart = Assets.AlertPart:Clone()::BasePart
    local finalSize = Vector3.new(0.001, 1 * radius * 2, 1 * radius * 2)
    alertPart.Size = Vector3.new(0.001 ,1, 1)
    alertPart.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    alertPart.Name = "_FishAlert"
    alertPart.Parent = workspace:WaitForChild("__THINGS")
    Functions.Tween(alertPart, { Size = finalSize }, { "Elastic", "Out", 1 }::{any})
    Functions.Tween(alertPart, { Transparency = 1 }, { "Sine", "Out", 1 }::{any}).Completed:Connect(function()
        alertPart:Destroy()
    end)    
end)