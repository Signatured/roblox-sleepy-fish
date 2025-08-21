--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pad = require(ReplicatedStorage.Library.Client.Pad)
local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local ProductCmds = require(ReplicatedStorage.Library.Client.ProductCmds)
local Save = require(ReplicatedStorage.Library.Client.Save)

local TAG = "PackOfferPad"
local OFFER_DISPLAY_TAG = "OfferDisplay"
local BILLBOARD_TAG = "PackBillboard"

-- Track all current OfferDisplay models (separately tagged)
local offerDisplays: {[Instance]: boolean} = {}
local billboards: {[Instance]: boolean} = {}

local function setModelVisibility(root: Instance, targetTransparency: number)
    for _, desc in ipairs(root:GetDescendants()) do
        if desc:GetAttribute("KeepTransparent") then
            continue
        end
        if desc:IsA("BasePart") then
            (desc :: BasePart).Transparency = targetTransparency
        end
    end
end

local function updateOfferVisibilityFor(display: Instance)
    if not display or not display.Parent then return end
    local ownsStarter = ProductCmds.Owns("Starter Pack")

    local starterModel: Model? = nil
    local expertModel: Model? = nil
    for _, d in ipairs(display:GetDescendants()) do
        if d:IsA("Model") then
            if d.Name == "StarterPackOffer" then
                starterModel = d
            elseif d.Name == "ExpertPackOffer" then
                expertModel = d
            end
        end
    end

    if starterModel then
        setModelVisibility(starterModel, ownsStarter and 1 or 0)
    end
    if expertModel then
        setModelVisibility(expertModel, ownsStarter and 0 or 1)
    end
end

local function updateAllOfferVisibilities()
    for inst in pairs(offerDisplays) do
        if inst and inst.Parent then
            updateOfferVisibilityFor(inst)
        end
    end
end

local function updateBillboardFor(gui: Instance)
    if not gui or not gui.Parent then return end
    if not gui:IsA("BillboardGui") then return end
    local ownsStarter = ProductCmds.Owns("Starter Pack")
    local title: TextLabel? = nil
    local subtitle: TextLabel? = nil

    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextLabel") then
            if d.Name == "Title" then
                title = d
            elseif d.Name == "Subtitle" then
                subtitle = d
            end
        end
    end

    if title then
        title.Text = ownsStarter and "Expert Pack!" or "Starter Pack!"
    end
    if subtitle then
        subtitle.Text = ownsStarter and "Only 79!" or "Only 9!"
    end
end

local function updateAllBillboards()
    for inst in pairs(billboards) do
        if inst and inst.Parent then
            updateBillboardFor(inst)
        end
    end
end

TagHook(OFFER_DISPLAY_TAG, function(inst: Instance)
    offerDisplays[inst] = true
    if Save.Get() ~= nil then
        updateOfferVisibilityFor(inst)
    end
    return function()
        offerDisplays[inst] = nil
    end
end)

TagHook(BILLBOARD_TAG, function(inst: Instance)
    billboards[inst] = true
    if Save.Get() ~= nil then
        updateBillboardFor(inst)
    end
    return function()
        billboards[inst] = nil
    end
end)

-- Listen for save stat updates and refresh all offer displays when Products changes
Save.Fired(function(key: string, _value: any)
    if key == "Products" then
        updateAllOfferVisibilities()
        updateAllBillboards()
    end
end)

TagHook(TAG, function(instance: Instance)
    if not instance:IsA("BasePart") and not instance:IsA("Model") then
        return function() end
    end

    -- React to save once available (OfferDisplays are handled globally)
    if Save.Get() == nil then
        local once
        once = Save.SaveAdded:Connect(function()
            pcall(function() once:Disconnect() end)
            updateAllOfferVisibilities()
            updateAllBillboards()
        end)
    else
        updateAllOfferVisibilities()
        updateAllBillboards()
    end

    local pad = Pad.new(instance)
    local conn = pad:AddEnterListener(function(player: Player)
        local function offer()
            local ownsStarter = ProductCmds.Owns("Starter Pack")
            local offerId = ownsStarter and ProductCmds.GetProductId("Expert Pack") or ProductCmds.GetProductId("Starter Pack")
            if offerId then
                Marketplace.Prompt(player, offerId, true)
            else
                warn("[PackOffers] Could not resolve product id for offer")
            end
        end

        if Save.Get() == nil then
            local once
            once = Save.SaveAdded:Connect(function()
                pcall(function() once:Disconnect() end)
                if pad:IsStandingOn(player) then
                    offer()
                end
            end)
        else
            offer()
        end
    end)

    return function()
        pcall(function() conn.Disconnect() end)
        pcall(function() pad:Destroy() end)
    end
end)


