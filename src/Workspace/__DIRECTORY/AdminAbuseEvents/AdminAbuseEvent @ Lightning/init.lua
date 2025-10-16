--!strict

return {
    DisplayName = "Lightning",
    Color = Color3.new(1, 1, 1),
    Icon = "rbxassetid://1234567890",
    ServerFunctions = {
        OnStart = function()
            print("Lightning started")
        end,
        Heartbeat = function(delta, time)
            print("Lightning rendered")
        end,
        OnStop = function()
            print("Lightning stopped")
        end,
    },
    ClientFunctions = {
        OnStart = function()
            print("Lightning started")
        end,
        RenderStepped = function(delta, time)
            print("Lightning rendered")
        end,
        OnStop = function()
            print("Lightning stopped")
        end,
    },
}