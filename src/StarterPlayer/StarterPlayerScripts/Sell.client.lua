--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Functions = require(ReplicatedStorage.Library.Functions)
local GamepassCmds = require(ReplicatedStorage.Library.Client.GamepassCmds)
local GamepassesDirectory = require(ReplicatedStorage.Game.Library.Directory.Gamepasses)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Network = require(ReplicatedStorage.Library.Client.Network)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local Audio = require(ReplicatedStorage.Library.Audio)
local Message = require(ReplicatedStorage.Library.Client.Message)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)

local _player = Players.LocalPlayer
local sellGui = GUI.Sell()
local frame = sellGui:WaitForChild("Frame")
local mainFrame = frame:WaitForChild("MainFrame")
local content = mainFrame:WaitForChild("Content")
local scrolling = content:WaitForChild("ScrollingFrame")
local template = scrolling:WaitForChild("SellFish")
local doubleMoney = frame:WaitForChild("DoubleMoney")
local doubleMoneyButton = doubleMoney:WaitForChild("ImageButton")
local doubleMoneyPrice = doubleMoney:WaitForChild("Price")
template.Visible = false

-- Footer controls
local sellAllButton = content:FindFirstChild("SellAll")
local inventoryValueLabel = content:FindFirstChild("InventoryValue")

local function getSellPrice(fishData: any): number
    local dir = Directory.Fish[fishData.FishId]
    if not dir then return 0 end
    -- Use OverrideSellPrice if it exists (for special items like pumpkins)
    local base
    if dir.OverrideSellPrice then
        base = dir.OverrideSellPrice
    else
        -- Server refuses Exclusive sales; still show price from base directory
        local level = fishData.Level or 1
        base = math.ceil((dir.MoneyPerSecond or 0) * level * 60 * 2)
    end
    -- Apply Double Money gamepass multiplier for display parity with server
    local schema = GamepassCmds.GetSchema("Double Money") or GamepassesDirectory["Double Money"]
    local ownsDouble = schema and GamepassCmds.Owns(schema) or false
    return ownsDouble and (base * 2) or base
end

local function clearList()
    for _, child in ipairs(scrolling:GetChildren()) do
        if child:IsA("Frame") and child.Name == "SellFishItem" then
            child:Destroy()
        end
    end
end

local function createItem(fishData: any)
    local dir = Directory.Fish[fishData.FishId]
    if not dir then return end

    local item = template:Clone()
    item.Name = "SellFishItem"
    item.Visible = true
    item.Parent = scrolling

    -- Image
    local fishContainer = item:FindFirstChild("FishContainer")
    local fishImage = fishContainer and fishContainer:FindFirstChild("FishImage")
    local imageLabel = fishImage and fishImage:FindFirstChild("ImageLabel")
    if imageLabel and imageLabel:IsA("ImageLabel") then
        imageLabel.Image = dir.Icon or ""
    end

    -- Title
    local title = item:FindFirstChild("Title")
    if title and title:IsA("TextLabel") then
        title.Text = dir.DisplayName or dir._id or fishData.FishId
    end

    -- Level
    local levelLabel = item:FindFirstChild("Level")
    if levelLabel and levelLabel:IsA("TextLabel") then
        levelLabel.Text = string.format("Level %d", fishData.Level or 1)
    end

    -- Price
    local priceLabel = item:FindFirstChild("Price")
    local priceAmount = getSellPrice(fishData)
    if priceLabel and priceLabel:IsA("TextLabel") then
        priceLabel.Text = "$" .. Functions.NumberShorten(priceAmount)
    end

    -- Background gradient by rarity
    local background = item:FindFirstChild("Background")
    local uiGrad = background and background:FindFirstChild("UIGradient")
    local r = dir.Rarity
    if background and background:IsA("ImageLabel") and r then
        local rarityId = r._id
        if rarityId == "Mythical" then
            if uiGrad and uiGrad:IsA("UIGradient") then
                uiGrad.Enabled = false
            end
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            local template = assets and assets:FindFirstChild("RainbowGradientWrapped")
            if template and template:IsA("UIGradient") then
                local grad = template:Clone()
                grad.Parent = background
                Functions.GradientScroll(grad, 2.5)
            end
        elseif rarityId == "God" then
            if uiGrad and uiGrad:IsA("UIGradient") then
                uiGrad.Enabled = false
            end
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            local template = assets and assets:FindFirstChild("GodGradient")
            if template and template:IsA("UIGradient") then
                local grad = template:Clone()
                grad.Parent = background
                Functions.GradientScroll(grad, 2.5)
            end
        elseif rarityId == "Secret" then
            if uiGrad and uiGrad:IsA("UIGradient") then
                uiGrad.Enabled = false
            end
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            local template = assets and assets:FindFirstChild("SecretGradient")
            if template and template:IsA("UIGradient") then
                local grad = template:Clone()
                grad.Parent = background
                Functions.GradientScroll(grad, 2.5)
            end
        else
            if uiGrad and uiGrad:IsA("UIGradient") then
                uiGrad.Enabled = true
                local color = (r :: any).Color or Color3.new(1, 1, 1)
                local h, s, v = color:ToHSV()
                local desat = Color3.fromHSV(h, math.max(0, s - 0.3), v)
                uiGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, color),
                    ColorSequenceKeypoint.new(1, desat),
                })
            end
        end
    end

    -- Sell button
    local sellButton = item:FindFirstChild("SellButton")
    if sellButton and sellButton:IsA("GuiButton") then
        ButtonFX(sellButton)
        sellButton.Activated:Connect(function()
            -- Confirm if Mythical/Secret
            local rarityId = dir.Rarity and dir.Rarity._id
            if rarityId == "Mythical" or rarityId == "God" or rarityId == "Secret" then
                local confirmText = string.format("Are you sure? You're selling a %s fish!", rarityId)
                local okConfirm = Message.new(confirmText, true)
                if not okConfirm then return end
            end
            local ok, result = Network.Invoke("SellMerchant_Sell", { fishData.UID })
            if ok and type(result) == "table" and result.Total and result.Total > 0 then
                Audio.Play("rbxassetid://132697192191142", script, 1, 0.6)
                local displayName = dir.DisplayName or dir._id or fishData.FishId
                NotificationCmds.Message(`You sold a {displayName} for ${Functions.NumberShorten(result.Total)}!`, { Color = Color3.fromRGB(0, 255, 0) })

                -- After sale, refresh list from save
                task.delay(0.05, function()
                    local current = Save.Get()
                    if current then
                        render()
                    end
                end)
            end
        end)
    end
end

function render()
    clearList()
    local save = Save.Get()
    if not save then return end
    local inv = save.Inventory
    if type(inv) ~= "table" then return end
    -- Sort by sale price (desc)
    table.sort(inv, function(a, b)
        return getSellPrice(a) > getSellPrice(b)
    end)
    for _, fishData in ipairs(inv) do
        createItem(fishData)
    end
    -- Update footer inventory value
    local total = 0
    for _, fishData in ipairs(inv) do
        local dir = Directory.Fish[fishData.FishId]
        local isExclusive = dir and dir.Rarity and dir.Rarity._id == "Exclusive"
        if dir and not isExclusive then
            total += getSellPrice(fishData)
        end
    end
    if inventoryValueLabel and inventoryValueLabel:IsA("TextLabel") then
        inventoryValueLabel.Text = "Inventory Value: $" .. Functions.NumberShorten(total)
    end
end

-- Reactive: re-render when inventory changes
Save.Fired(function(key: string, _value: any)
    if key == "Inventory" then
        render()
    end
end)

-- Render on open via TabController
TabController.Opened:Connect(function(tabId: string)
    if tabId == "Sell" then
        render()

        task.spawn(function()
            while true do
                if TabController.GetCurrentTab() ~= "Sell" then break end
                Functions.UpdateCanvasSize(scrolling)
                task.wait(0.1)
            end
        end)
    end
end)

-- Wire SellAll behavior
if sellAllButton and sellAllButton:IsA("GuiButton") then
    ButtonFX(sellAllButton)
    sellAllButton.Activated:Connect(function()
        local save = Save.Get()
        if not save or type(save.Inventory) ~= "table" then return end
        local uids = {}
        local hasMythical = false
        local hasGod = false
        local hasSecret = false
        for _, entry in ipairs(save.Inventory) do
            local dir = Directory.Fish[entry.FishId]
            if dir and not (dir.Rarity and dir.Rarity._id == "Exclusive") then
                local rarityId = dir.Rarity and dir.Rarity._id
                if rarityId == "Mythical" then hasMythical = true end
                if rarityId == "God" then hasGod = true end
                if rarityId == "Secret" then hasSecret = true end
                table.insert(uids, entry.UID)
            end
        end
        if #uids == 0 then return end
        -- Confirm if selling any Mythical/Secret
        if hasSecret or hasMythical or hasGod then
            local which = hasSecret and "Secret" or hasMythical and "Mythical" or hasGod and "God" or "fish"
            local okConfirm = Message.new(string.format("Are you sure? You're selling a %s fish!", which), true)
            if not okConfirm then return end
        end
        local ok, result = Network.Invoke("SellMerchant_Sell", uids)
        if ok and type(result) == "table" then
            task.defer(render)
            Audio.Play("rbxassetid://132697192191142", script, 1, 0.6)
            local total = result.Total or 0
            NotificationCmds.Message(`You sold your inventory for ${Functions.NumberShorten(total)}!`, { Color = Color3.fromRGB(0, 255, 0) })
        end
    end)
end

-- One-time setup: Double Money CTA (button + price)
do
    local schema = GamepassCmds.GetSchema("Double Money") or GamepassesDirectory["Double Money"]
    if schema then
        if doubleMoneyButton and doubleMoneyButton:IsA("GuiButton") then
            ButtonFX(doubleMoneyButton)
            doubleMoneyButton.Activated:Connect(function()
                Marketplace.Prompt(Players.LocalPlayer, schema.GamepassId, false)
            end)
        end
        if doubleMoneyPrice and doubleMoneyPrice:IsA("TextLabel") then
            local price = Functions.GetRobuxPrice(schema.GamepassId) or 0
            doubleMoneyPrice.Text = tostring(price)
        end
    end
end

-- Toggle the Double Money CTA visibility based on ownership
local function refreshDoubleMoneyCTA()
    local schema = GamepassCmds.GetSchema("Double Money") or GamepassesDirectory["Double Money"]
    local owns = schema and GamepassCmds.Owns(schema) or false
    if doubleMoney and doubleMoney:IsA("Frame") then
        doubleMoney.Visible = not owns
    end
end

-- Initial state
refreshDoubleMoneyCTA()

-- Hide CTA when gamepasses update
Save.Fired(function(key: string, _value: any)
    if key == "Gamepasses" then
        refreshDoubleMoneyCTA()
        render()
    end
end)


