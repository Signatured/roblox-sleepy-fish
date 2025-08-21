--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)

local ServerLuck = {}

local multiplier: number = 1
local timeLeft: number = 0

function ServerLuck.GetMultiplier(): number
    return multiplier
end

function ServerLuck.GetTimeLeft(): number
    return math.max(0, timeLeft)
end

local function requestSync()
    local m, t = Network.Invoke("ServerLuck_Get")
    if typeof(m) == "number" and typeof(t) == "number" then
        multiplier = m
        timeLeft = t
    end
end

Network.Fired("ServerLuck_Update", function(m: number, t: number)
    multiplier = m
    timeLeft = t
end)

task.spawn(requestSync)

return ServerLuck



