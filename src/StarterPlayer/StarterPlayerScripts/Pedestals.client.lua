--!strict

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Assets = game.ReplicatedStorage.Assets

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ButtonFX = require(game.ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local FishCmds = require(game.ReplicatedStorage.Game.Library.Client.FishCmds)
local PlotTypes = require(game.ReplicatedStorage.Game.Library.Types.Plots)
local Directory = require(game.ReplicatedStorage.Game.Library.Directory)

type PedestalModel = {
    Model: Model,
    Billboard: BillboardGui,
    SellProximity: ProximityPrompt,
    PickupProximity: ProximityPrompt,
}

local pedestalModels: {[ClientPlot.Type]: {[number]: PedestalModel}} = {}

function TogglePedestal(model: Model, toggle: boolean, transparency: number?)
    if not transparency then
        transparency = toggle and 0 or 1
    end

    if not toggle then
        transparency = 1
    end

    assert(transparency)

    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Transparency = transparency
            child.CanCollide = toggle
        elseif child:IsA("SurfaceGui") then
            child.Enabled = toggle
        end
    end
end

function SetupProximity(text: string, holdDuration: number, keyboardKeyCode: Enum.KeyCode, attachment: Attachment): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 8
	prompt.KeyboardKeyCode = keyboardKeyCode
    prompt.RequiresLineOfSight = false
	prompt.Parent = attachment

    return prompt
end

function SetupBillboard(model: Model, fishData: PlotTypes.Fish): BillboardGui
    local primaryPart = assert(model.PrimaryPart)
    local dir = Directory.Fish[fishData.FishId]
    local billboardOffset = dir.BillboardOffset

    local billboard = Assets.FishPedestalGui:Clone()::BillboardGui
    billboard.StudsOffsetWorldSpace = Vector3.new(0, billboardOffset, 0)
    billboard.Parent = primaryPart

    return billboard
end

function UpdateBillboard(plot: ClientPlot.Type, index: number, billboard: BillboardGui)
    local fishData = plot:GetFish(index)
    if not fishData then
        return
    end

    local dir = Directory.Fish[fishData.FishId]
    local earnings = plot:GetFishEarnings(index)

    local frame = billboard:WaitForChild("Frame")::Frame
    local displayName = frame:WaitForChild("DisplayName")::TextLabel
    local moneyPerSecond = frame:WaitForChild("MoneyPerSecond")::TextLabel
    local money = frame:WaitForChild("Money")::TextLabel
    local rarity = frame:WaitForChild("Rarity")::TextLabel
    local level = frame:WaitForChild("Level")::TextLabel

    displayName.Text = dir.DisplayName
    rarity.Text = dir.Rarity.DisplayName
    rarity.TextColor3 = dir.Rarity.Color
    level.Text = `Level {fishData.FishData.Level}`
    moneyPerSecond.Text = `${Functions.NumberShorten(plot:GetMoneyPerSecond(index) or 0)}/s`
    money.Text = `${Functions.NumberShorten(earnings)}`
end

local function SetupButtons(plot: ClientPlot.Type, model: Model, buyFrame: Frame, upgradeFrame: Frame, placeFrame: Frame)
    if model:GetAttribute("_ButtonsInit") then
        return
    end
    model:SetAttribute("_ButtonsInit", true)
    local pedestalId = tonumber(model.Name)::number

    local buyButton = buyFrame:WaitForChild("Button")::GuiButton
    ButtonFX(buyButton)
    buyButton.MouseButton1Click:Connect(function()
        local success, msg = plot:Invoke("BuyPedestal", pedestalId)
        if not success and not msg then
            return
        end

        if not success and msg then
            NotificationCmds.Message(msg, {
                Color = Color3.fromRGB(255, 0, 0),
            })
        end
    end)

    local upgradeButton = upgradeFrame:WaitForChild("Button")::GuiButton
    ButtonFX(upgradeButton)
    upgradeButton.MouseButton1Click:Connect(function()
        local cost = plot:GetUpgradeCost(pedestalId)
        if not cost then
            NotificationCmds.Message("Fish is already at max level!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        if not plot:CanAfford(cost) then
            NotificationCmds.Message("Not enough money!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        plot:Invoke("UpgradeFish", pedestalId)
    end)

    local placeButton = placeFrame:WaitForChild("Button")::GuiButton
    ButtonFX(placeButton)
    placeButton.MouseButton1Click:Connect(function()
        local fishData = FishCmds.GetCurrentFishData()
        if not fishData then
            NotificationCmds.Message("Equip a fish to place it!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        plot:Invoke("CreateFish", pedestalId, fishData.UID)
    end)
end

function UpdatePedestal(plot: ClientPlot.Type, model: Model)
    local pedestalId = tonumber(model.Name)::number
    local pedestalCount = plot:Save("Pedestals")::number
    local fish = plot:Save("Fish")::{[string]: PlotTypes.Fish}

    local nameplate = model:WaitForChild("Nameplate")::BasePart
    local base = model:WaitForChild("Base")::BasePart
    local sellAttachment = base:WaitForChild("SellAttachment")::Attachment
    local pickupAttachment = base:WaitForChild("PickupAttachment")::Attachment
    local surfaceGui = nameplate:WaitForChild("SurfaceGui")::SurfaceGui

    -- Hook Claim part touch once per pedestal; print once per continuous contact by the local player
    if not model:GetAttribute("_ClaimHooked") then
        local claim = model:FindFirstChild("Claim", true)
        if claim and claim:IsA("BasePart") then
            model:SetAttribute("_ClaimHooked", true)
            local touchingParts: {[BasePart]: boolean} = {}
            claim.Touched:Connect(function(other: BasePart)
                local character = LocalPlayer and LocalPlayer.Character
                if not character or not other or not other:IsDescendantOf(character) then return end
                if not touchingParts[other] then
                    touchingParts[other] = true
                end
                if model:GetAttribute("_ClaimActive") ~= true then
                    plot:Invoke("ClaimEarnings", pedestalId)
                    model:SetAttribute("_ClaimActive", true)
                end
            end)
            claim.TouchEnded:Connect(function(other: BasePart)
                local character = LocalPlayer and LocalPlayer.Character
                if not character or not other or not other:IsDescendantOf(character) then return end
                touchingParts[other] = nil
                -- If no more local parts are touching, reset active state
                local any = false
                for _ in pairs(touchingParts) do
                    any = true
                    break
                end
                if not any then
                    model:SetAttribute("_ClaimActive", false)
                end
            end)
        end
    end

    local frame = surfaceGui:WaitForChild("Frame")::Frame
    local buyFrame = frame:WaitForChild("Buy")::Frame
    local upgradeFrame = frame:WaitForChild("Upgrade")::Frame
    local placeFrame = frame:WaitForChild("Place")::Frame

    SetupButtons(plot, model, buyFrame, upgradeFrame, placeFrame)

    if pedestalId > pedestalCount + 1 then
        TogglePedestal(model, false)
        return
    end

    if pedestalId == pedestalCount + 1 then
        TogglePedestal(model, true, 0.5)

        buyFrame.Visible = true
        upgradeFrame.Visible = false
        placeFrame.Visible = false

        local buyButton = buyFrame:FindFirstChild("Button")::ImageButton
		local buttonText = buyButton:FindFirstChild("TextLabel")::TextLabel

        local cost = PlotTypes.PedestalCost(pedestalId)
        if not cost then
            buttonText.Text = "Max!"
            return
        end

        buttonText.Text = `${Functions.NumberShorten(cost)}`
    else
        TogglePedestal(model, true)

        local fishData = fish[tostring(pedestalId)]
        if fishData then
            buyFrame.Visible = false
            upgradeFrame.Visible = true
            placeFrame.Visible = false

            local textLabel = upgradeFrame:WaitForChild("TextLabel")::TextLabel
            textLabel.Text = `Level {fishData.FishData.Level} -> Level {fishData.FishData.Level + 1}`

            local upgradeButton = upgradeFrame:FindFirstChild("Button")::ImageButton
            local buttonText = upgradeButton:FindFirstChild("TextLabel")::TextLabel

            local cost = plot:GetUpgradeCost(pedestalId)
            if not cost then
                buttonText.Text = "Max!"
                return
            end

            buttonText.Text = `${Functions.NumberShorten(cost)}`
        else
            buyFrame.Visible = false
            upgradeFrame.Visible = false
            placeFrame.Visible = true
        end
    end

    local fishData = fish[tostring(pedestalId)]
    if fishData and pedestalModels[plot] and not pedestalModels[plot][pedestalId] then
        local dir = Directory.Fish[fishData.FishId]
        local fishModel = dir._script:WaitForChild("Model"):Clone()::Model
        local plotFishFolder = workspace:WaitForChild("__THINGS"):WaitForChild("PlotFish")

        fishModel:PivotTo(base:GetPivot() + Vector3.new(0, base.Size.Y / 2, 0) + Vector3.new(0, fishModel:GetExtentsSize().Y / 2, 0))
        fishModel.Parent = plotFishFolder

        local sellProximity = SetupProximity("Sell", 3, Enum.KeyCode.E, sellAttachment)
        local pickupProximity = SetupProximity("Pickup", 1, Enum.KeyCode.F, pickupAttachment)
        local billboard = SetupBillboard(fishModel, fishData)
        UpdateBillboard(plot, pedestalId, billboard)

        pedestalModels[plot][pedestalId] = {
            Model = fishModel,
            Billboard = billboard,
            SellProximity = sellProximity,
            PickupProximity = pickupProximity,
        }
    elseif not fishData and pedestalModels[plot] and pedestalModels[plot][pedestalId] then
        local fishModel = pedestalModels[plot][pedestalId]
        fishModel.Model:Destroy()
        fishModel.SellProximity:Destroy()
        fishModel.PickupProximity:Destroy()
        pedestalModels[plot][pedestalId] = nil
    end

    if pedestalModels[plot][pedestalId] then
        UpdateBillboard(plot, pedestalId, pedestalModels[plot][pedestalId].Billboard)
    end
end

ClientPlot.Created:Connect(function(plot: ClientPlot.Type)
    pedestalModels[plot] = {}

    local model = plot:WaitModel()
    local pedestals = model:WaitForChild("Pedestals")::Model

    for _, child in pedestals:GetChildren() do
        UpdatePedestal(plot, child::Model)
    end

    plot:SaveChanged("Pedestals"):Connect(function(newCount: number)
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
        end
    end)

    plot:SaveChanged("Fish"):Connect(function(newFish: {[string]: PlotTypes.Fish})
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
        end
    end)
end)

ClientPlot.Destroying:Connect(function(plot: ClientPlot.Type)
    for _, model in pairs(pedestalModels[plot]) do
        model.Model:Destroy()
        model.SellProximity:Destroy()
        model.PickupProximity:Destroy()
    end
    pedestalModels[plot] = nil
end)

task.spawn(function()
    while true do
        for plot, models in pairs(pedestalModels) do
            for index, model in pairs(models) do
                UpdateBillboard(plot, index, model.Billboard)
            end
        end
        task.wait(1)
    end
end)