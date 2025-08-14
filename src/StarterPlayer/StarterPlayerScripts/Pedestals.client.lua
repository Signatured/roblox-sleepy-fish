--!strict

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ButtonFX = require(game.ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local DefaultStats = require(game.ReplicatedStorage.Game.Modules.DefaultStats)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local FishCmds = require(game.ReplicatedStorage.Game.GameClientLibrary.FishCmds)
local PlotTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Plots)
local Directory = require(game.ReplicatedStorage.Game.GameLibrary.Directory)

local pedestalModels: {[ClientPlot.Type]: {[number]: Model}} = {}

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

local function SetupButtons(plot: ClientPlot.Type, model: Model, buyFrame: Frame, upgradeFrame: Frame, placeFrame: Frame)
    if model:GetAttribute("_ButtonsInit") then
        return
    end
    model:SetAttribute("_ButtonsInit", true)

    local buyButton = buyFrame:WaitForChild("Button")::GuiButton
    ButtonFX(buyButton)
    buyButton.MouseButton1Click:Connect(function()
        local success, msg = plot:Invoke("BuyPedestal", model:GetAttribute("Id"))
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
        local cost = plot:GetUpgradeCost(model:GetAttribute("Id")::number)
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

        plot:Invoke("UpgradeFish", model:GetAttribute("Id"))
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

        plot:Invoke("CreateFish", model:GetAttribute("Id"), fishData.UID)
    end)
end

function UpdatePedestal(plot: ClientPlot.Type, model: Model)
    local pedestalId = model:GetAttribute("Id")::number
    local pedestalCount = plot:Save("Pedestals")::number
    local fish = plot:Save("Fish")::{[string]: PlotTypes.Fish}

    local nameplate = model:WaitForChild("Nameplate")::BasePart
    local base = model:WaitForChild("Base")::BasePart
    local surfaceGui = nameplate:WaitForChild("SurfaceGui")::SurfaceGui

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
            textLabel.Text = `{fishData.FishData.Level} -> {fishData.FishData.Level + 1}`

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

        fishModel:PivotTo(base:GetPivot() + Vector3.new(0, base.Size.Y / 2, 0))
        fishModel.Parent = plotFishFolder
        pedestalModels[plot][pedestalId] = fishModel
    elseif not fishData and pedestalModels[plot] and pedestalModels[plot][pedestalId] then
        local fishModel = pedestalModels[plot][pedestalId]
        fishModel:Destroy()
        pedestalModels[plot][pedestalId] = nil
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
    for _, model in pedestalModels[plot] do
        model:Destroy()
    end
    pedestalModels[plot] = nil
end)