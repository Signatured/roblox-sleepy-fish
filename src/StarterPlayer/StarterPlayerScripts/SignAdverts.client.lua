--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local GUIFX_Button = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local GetRobuxPrice = require(ReplicatedStorage.Library.Functions.GetRobuxPrice)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)
local Gamepasses = require(ReplicatedStorage.Game.Library.Directory.Gamepasses)
local ProductCmds = require(ReplicatedStorage.Library.Client.ProductCmds)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Signal = require(ReplicatedStorage.Library.Signal)

local function getFirstSurfaceGui(model: Model): SurfaceGui?
    for _, inst in ipairs(model:GetDescendants()) do
        if inst:IsA("SurfaceGui") then
            return inst
        end
    end
    return nil
end

-- Track active signs to support refreshes when save updates
local activeSigns: {[Instance]: boolean} = {}

local function shouldDestroy(model: Model): boolean
    local productIdAttrVal = model:GetAttribute("ProductId")
    local gamepassIdAttrVal = model:GetAttribute("GamepassId")
    local productIdAttr: string? = nil
    local gamepassIdAttr: string? = nil
    if typeof(productIdAttrVal) == "string" then productIdAttr = productIdAttrVal :: string end
    if typeof(gamepassIdAttrVal) == "string" then gamepassIdAttr = gamepassIdAttrVal :: string end

    if productIdAttr then
        local product = Products[productIdAttr]
        if product and ProductCmds.Owns(product._id) then
            return true
        end
    elseif gamepassIdAttr then
        local gp = Gamepasses[gamepassIdAttr]
        if gp then
            local data = Save.Get()
            if data and data.Gamepasses and data.Gamepasses[tostring(gp.GamepassId)] == true then
                return true
            end
        end
    end
    return false
end

local function setupSign(model: Model)
    local gui = getFirstSurfaceGui(model)
    if not gui then return end

    -- Determine directory id attributes
    local productIdAttrVal = model:GetAttribute("ProductId")
    local gamepassIdAttrVal = model:GetAttribute("GamepassId")
    local productIdAttr: string? = nil
    local gamepassIdAttr: string? = nil
    if typeof(productIdAttrVal) == "string" then
        productIdAttr = productIdAttrVal :: string
    end
    if typeof(gamepassIdAttrVal) == "string" then
        gamepassIdAttr = gamepassIdAttrVal :: string
    end

    local isProduct = productIdAttr ~= nil
    local isGamepass = gamepassIdAttr ~= nil
    if not isProduct and not isGamepass then return end

    -- Resolve schema and ownership
    if isProduct then
        local product = Products[productIdAttr :: string]
        if not product then return end
        if ProductCmds.Owns(product._id) then
            model:Destroy()
            return
        end

        -- Wire all GuiButtons with ButtonFX and prompt behavior
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("GuiButton") then
                GUIFX_Button(d)
                d.Activated:Connect(function()
                    Marketplace.Prompt(game.Players.LocalPlayer, product.ProductId, true)
                end)
            end
        end
        -- Set price label if present
        local priceLabel = gui:FindFirstChild("Price", true)
        if priceLabel and priceLabel:IsA("TextLabel") then
            local price = GetRobuxPrice(product.ProductId, true)
            if price then
                priceLabel.Text = `{price}`
            else
                priceLabel.Text = "???"
            end
        end
        return
    end

    if isGamepass then
        local gp = Gamepasses[gamepassIdAttr :: string]
        if not gp then return end

        -- We don't have a client GamepassCmds; rely on Save in ProductCmds pattern not applicable.
        -- Fallback: if Save replicates gamepasses, check there; otherwise skip destroy and just show.
        local saveModule = ReplicatedStorage:FindFirstChild("Library") and require(ReplicatedStorage.Library.Client.Save)
        local owned = false
        local ok, save = pcall(function()
            return saveModule and saveModule.Get() or nil
        end)
        if ok and save and save.Gamepasses and save.Gamepasses[tostring(gp.GamepassId)] == true then
            owned = true
        end
        if owned then
            model:Destroy()
            return
        end

        -- Wire buttons
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("GuiButton") then
                GUIFX_Button(d)
                d.Activated:Connect(function()
                    Marketplace.Prompt(game.Players.LocalPlayer, gp.GamepassId, false)
                end)
            end
        end
        -- Set price label
        local priceLabel = gui:FindFirstChild("Price", true)
        if priceLabel and priceLabel:IsA("TextLabel") then
            local price = GetRobuxPrice(gp.GamepassId, false)
            if price then
                priceLabel.Text = `{price}`
            else
                priceLabel.Text = "???"
            end
        end
    end
end

TagHook("AdvertSign", function(inst: Instance)
    if not inst:IsA("Model") then
        return function() end
    end
    activeSigns[inst] = true
    setupSign(inst)
    return function()
        activeSigns[inst] = nil
    end
end)

local function refreshAllSigns()
    local toRemove: {Instance} = {}
    for inst in pairs(activeSigns) do
        local model = inst
        if not model or not model.Parent then
            table.insert(toRemove, inst)
        elseif model:IsA("Model") then
            local m = model :: Model
            if shouldDestroy(m) then
                table.insert(toRemove, inst)
                m:Destroy()
            end
        else
            table.insert(toRemove, inst)
        end
    end
    for _, inst in ipairs(toRemove) do
        activeSigns[inst] = nil
    end
end

Signal.Fired("StatCacheUpdated"):Connect(function(key, _value)
    if key == "Gamepasses" or key == "Products" then
        refreshAllSigns()
    end
end)