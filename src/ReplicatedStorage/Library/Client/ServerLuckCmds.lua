--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Functions = require(ReplicatedStorage.Library.Functions)

local ServerLuck = {}

local multiplier: number = 1
local timeLeft: number = 0
local recentActivators: {string} = {}

function ServerLuck.GetMultiplier(): number
    return multiplier
end

function ServerLuck.GetTimeLeft(): number
    return math.max(0, timeLeft)
end

local function requestSync()
    local m, t, recent = Network.Invoke("ServerLuck_Get")
    if typeof(m) == "number" and typeof(t) == "number" then
        multiplier = m
        timeLeft = t
        if typeof(recent) == "table" then
            recentActivators = recent
        end
    end
end

Network.Fired("ServerLuck_Update", function(m: number, t: number)
    multiplier = m
    timeLeft = t
end)

task.spawn(requestSync)

-- Billboard UI sync via TagHook
local function updateBillboard(billboard: BillboardGui)
    local frame = billboard:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return end
    local title = billboard:FindFirstChild("Title")
    local subtitle = billboard:FindFirstChild("Subtitle")
    local activatorTemplate = frame:FindFirstChild("Activator")

    if multiplier <= 1 then
        billboard.Enabled = false
        return
    end
    billboard.Enabled = true

    if title and title:IsA("TextLabel") then
        if multiplier >= 4 then
            title.Text = "4x Server Luck Active!"
        else
            title.Text = "2x Server Luck Active!"
        end
    end
    if subtitle and subtitle:IsA("TextLabel") then
        subtitle.Text = "Lasts for " .. Functions.FormatTime(math.max(0, timeLeft)) .. "!"
    end
    if activatorTemplate and activatorTemplate:IsA("TextLabel") then
        activatorTemplate.Visible = false
        -- rebuild unique recent activators UI (up to 2)
        -- clear existing clones
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextLabel") and child ~= activatorTemplate and child.Name == "ActivatorClone" then
                child:Destroy()
            end
        end
        local count = 0
        for i = #recentActivators, 1, -1 do
            local displayName = recentActivators[i]
            local clone = activatorTemplate:Clone()
            clone.Name = "ActivatorClone"
            clone.Visible = true
            clone.Text = "Activated by @" .. displayName
            clone.Parent = frame
            count += 1
            if count >= 2 then break end
        end
    end
end

-- Keep UI ticking for countdown
local accum = 0
RunService.Heartbeat:Connect(function(dt)
    accum += (typeof(dt) == "number") and dt or 0
    if accum < 1 then return end
    accum -= 1
    if multiplier > 1 and timeLeft > 0 then
        timeLeft = math.max(0, timeLeft - 1)
    end
    local tagged = game.CollectionService and game.CollectionService:GetTagged("ServerLuckBillboard") or {}
    for _, gui in ipairs(tagged) do
        if gui:IsA("BillboardGui") then
            updateBillboard(gui)
        end
    end
end)

-- Track activators list (networked from server if available)
Network.Fired("ServerLuck_Activator", function(displayName: string)
    if typeof(displayName) ~= "string" then return end
    -- Deduplicate while keeping order
    local newList: {string} = {}
    table.insert(newList, displayName)
    for _, name in ipairs(recentActivators) do
        if name ~= displayName then table.insert(newList, name) end
    end
    -- Trim to last two unique
    while #newList > 2 do
        table.remove(newList)
    end
    recentActivators = newList
    -- immediate UI refresh
    local tagged = game.CollectionService and game.CollectionService:GetTagged("ServerLuckBillboard") or {}
    for _, gui in ipairs(tagged) do
        if gui:IsA("BillboardGui") then
            updateBillboard(gui)
        end
    end
end)

return ServerLuck



