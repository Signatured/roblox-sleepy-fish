--!strict

-- Client-side Gift commands: prompt in HomeBase and GUI accept/decline

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)
local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local ButtonFX = require(Library.Client.GUIFX.ButtonFX)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local Functions = require(ReplicatedStorage.Library.Functions)
local GadgetCmds = require(ReplicatedStorage.Game.Library.Client.GadgetCmds)
local FishCmds = require(ReplicatedStorage.Game.Library.Client.FishCmds)

local GiftCmds = {}

local localPlayer = Players.LocalPlayer
local activePromptTargets: {[number]: ProximityPrompt} = {}

local function isLocalHoldingSomething(): (boolean, string?, any?)
    -- Try fish first
    local fishData = FishCmds.GetCurrentFishData and FishCmds.GetCurrentFishData()
    if fishData then
        return true, "Fish", fishData
    end
    -- Try gadget
    local currentGadget = GadgetCmds.GetCurrent and GadgetCmds.GetCurrent()
    if currentGadget then
        return true, "Gadget", currentGadget
    end
    return false, nil, nil
end

local function getHomeBasePart(): BasePart?
    local root = workspace:FindFirstChild("__THINGS")
    return root and root:FindFirstChild("HomeBase") :: BasePart
end

-- Ensure a proximity prompt exists on target and wired to GiveHand
local function ensureGiftPromptFor(target: Player)
    local character = target.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp:IsA("BasePart") then return end
    if activePromptTargets[target.UserId] and activePromptTargets[target.UserId].Parent == hrp then
        return
    end
    -- Create a new prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "GiftProximityPrompt"
    prompt.ActionText = "Gift!"
    prompt.ObjectText = "@" .. tostring(target.Name)
    prompt.HoldDuration = 2.5
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = hrp

    prompt.Triggered:Connect(function(playerWhoTriggered: Player)
        if playerWhoTriggered ~= localPlayer then return end
        GiftCmds.GiveHand(target)
    end)

    activePromptTargets[target.UserId] = prompt
end

local function clearAllPrompts()
    for userId, prompt in pairs(activePromptTargets) do
        if prompt then prompt:Destroy() end
        activePromptTargets[userId] = nil
    end
end

-- Call to give item in hand to target player
function GiftCmds.GiveHand(targetPlayer: Player): boolean
    local holding, kind, data = isLocalHoldingSomething()
    if not holding or not kind then
        NotificationCmds.Message("You need to be holding something to gift it!", { Color = Color3.fromRGB(255, 80, 80) })
        return false
    end

    local payload
    if kind == "Fish" then
        local fishData = data
        if not fishData or not fishData.UID then
            NotificationCmds.Message("Could not find your fish in hand.", { Color = Color3.fromRGB(255, 80, 80) })
            return false
        end
        payload = { ItemType = "Fish", UID = fishData.UID }
    else
        local gadgetDir = data
        if not gadgetDir or not gadgetDir._id then
            NotificationCmds.Message("Could not find your gadget in hand.", { Color = Color3.fromRGB(255, 80, 80) })
            return false
        end
        payload = { ItemType = "Gadget", GadgetId = gadgetDir._id }
    end

    local ok, resultOrMsg = pcall(function()
        return Network.Invoke("GiftRequest", targetPlayer.UserId, payload)
    end)
    if not ok then
        NotificationCmds.Message("Something went wrong.", { Color = Color3.fromRGB(255, 80, 80) })
        return false
    end
    if resultOrMsg ~= true then
        NotificationCmds.Message(tostring(resultOrMsg), { Color = Color3.fromRGB(255, 80, 80) })
        return false
    end
    return true
end

-- Listen for offers from server -> open Gift GUI
Network.Fired("GiftOffered", function(data)
    local gui = GUI.Gift()
    if not gui then return end
    gui.Enabled = true
    local frame = gui:WaitForChild("Frame")
    local main = frame and frame:FindFirstChild("Frame") and (frame :: Instance):FindFirstChild("Frame")
    local mainFrame = frame and main:FindFirstChild("Main") or (main and main:FindFirstChild("Main"))
    local buttons = mainFrame and mainFrame:FindFirstChild("Buttons")
    local decline = buttons and buttons:FindFirstChild("DeclineButton")
    local accept = buttons and buttons:FindFirstChild("AcceptButton")
    local giftFrom = mainFrame and mainFrame:FindFirstChild("GiftFrom")
    local giftedItem = mainFrame and mainFrame:FindFirstChild("GiftedItem")

    if giftFrom and giftFrom:IsA("TextLabel") then
        giftFrom.Text = "Gift from " .. tostring(data.FromName) .. "!"
    end
    if giftedItem and giftedItem:IsA("TextLabel") then
        giftedItem.Text = tostring(data.ItemText)
    end

    if accept and accept:IsA("GuiButton") then ButtonFX(accept) end
    if decline and decline:IsA("GuiButton") then ButtonFX(decline) end

    if accept and accept:IsA("GuiButton") then
        accept.Activated:Connect(function()
            gui.Enabled = false
            pcall(function()
                Network.Invoke("GiftAccept")
            end)
        end)
    end
    if decline and decline:IsA("GuiButton") then
        decline.Activated:Connect(function()
            gui.Enabled = false
            pcall(function()
                Network.Invoke("GiftDecline")
            end)
        end)
    end
end)

-- Listen for simple gift result notifications
Network.Fired("GiftResult", function(payload)
    if payload and payload.Message then
        NotificationCmds.Message(tostring(payload.Message), { Color = Color3.fromRGB(140, 255, 140) })
    end
end)

-- Heartbeat watcher to show prompts for players inside HomeBase while local is holding an item
RunService.Heartbeat:Connect(function()
    local holding = isLocalHoldingSomething()
    local home = getHomeBasePart()
    if not holding or not home then
        clearAllPrompts()
        return
    end
    local myChar = localPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP or not myHRP:IsA("BasePart") then
        clearAllPrompts(); return
    end

    -- Build the set of who should have prompts
    local shouldHave: {[number]: boolean} = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local c = p.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:IsA("BasePart") then
                local inPart = Functions.IsPositionInPart(hrp.Position, home)
                if inPart then
                    ensureGiftPromptFor(p)
                    shouldHave[p.UserId] = true
                end
            end
        end
    end
    -- Cleanup any prompts for players who no longer qualify
    for userId, prompt in pairs(activePromptTargets) do
        if not shouldHave[userId] then
            if prompt then prompt:Destroy() end
            activePromptTargets[userId] = nil
        end
    end
end)

return GiftCmds


