--!strict

local _RunService = game:GetService("RunService")
local _Players = game:GetService("Players")

local _ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(game.ServerScriptService.Library.Network)

local ServerLuck = {}

local currentMultiplier: number = 1
local expiryTime: number? = nil -- server time when boost ends
local timerRunning = false

local function getNow(): number
    return workspace:GetServerTimeNow()
end

local function getTimeLeftInternal(): number
    local exp = expiryTime
    if not exp then return 0 end
    return math.max(0, exp - getNow())
end

local function broadcast()
    Network.FireAll("ServerLuck_Update", currentMultiplier, getTimeLeftInternal())
end

local function startTimerIfNeeded()
    if timerRunning then return end
    if currentMultiplier <= 1 or not expiryTime then return end
    timerRunning = true
    task.spawn(function()
        while currentMultiplier > 1 do
            if getTimeLeftInternal() <= 0 then
                currentMultiplier = 1
                expiryTime = nil
                broadcast()
                break
            end
            task.wait(1)
        end
        timerRunning = false
    end)
end

function ServerLuck.GetServerLuck(): number
    return currentMultiplier
end

function ServerLuck.GetTimeLeft(): number
    return getTimeLeftInternal()
end

-- Increases multiplier to 2x for 20 minutes. Cannot purchase if multiplier > 1x.
function ServerLuck.Activate2xLuck(): boolean
    if currentMultiplier > 1 then
        return false
    end
    currentMultiplier = 2
    expiryTime = getNow() + (20 * 60)
    broadcast()
    startTimerIfNeeded()
    return true
end

-- Sets multiplier to 4x and extends timer by 20 minutes. Only if current multiplier >= 2.
function ServerLuck.Activate4xLuck(): boolean
    if currentMultiplier < 2 then
        return false
    end
    currentMultiplier = 4
    local now = getNow()
    if not expiryTime or expiryTime < now then
        expiryTime = now + (20 * 60)
    else
        expiryTime += (20 * 60)
    end
    broadcast()
    startTimerIfNeeded()
    return true
end

-- Networking
Network.Invoked("ServerLuck_Get", function(_player: Player)
    return currentMultiplier, getTimeLeftInternal()
end)

return ServerLuck


