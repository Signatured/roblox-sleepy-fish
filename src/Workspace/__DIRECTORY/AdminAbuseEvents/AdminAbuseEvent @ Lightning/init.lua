--!strict

return {
    DisplayName = "Lightning",
    Color = Color3.fromRGB(100, 193, 255),
    Icon = "rbxassetid://1234567890",
    ServerFunctions = {
        OnStart = function()
            print("Lightning started")
        end,
        Heartbeat = function(delta, time)
        end,
        OnStop = function()
            print("Lightning stopped")
        end,
    },
    ClientFunctions = {
        OnStart = function()
            print("Lightning started")

            local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)

            NotificationCmds.Message("A storm is brewing...", {
                Color = Color3.fromRGB(100, 193, 255),
                Time = 8,
            })
        end,
        RenderStepped = function(delta, time)
        end,
        OnStop = function()
            local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)

            NotificationCmds.Message("The storm has passed...", {
                Color = Color3.fromRGB(100, 193, 255),
                Time = 8,
            })
        end,
    },
}