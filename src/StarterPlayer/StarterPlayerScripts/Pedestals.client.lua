--!strict

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ButtonFX = require(game.ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local DefaultStats = require(game.ReplicatedStorage.Game.Modules.DefaultStats)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)

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
        print("upgrade was presssed hahaah")
    end)

    local placeButton = placeFrame:WaitForChild("Button")::GuiButton
    ButtonFX(placeButton)
    placeButton.MouseButton1Click:Connect(function()
        print("now place was presssed")
    end)
end

function UpdatePedestal(plot: ClientPlot.Type, model: Model)
    local pedestalId = model:GetAttribute("Id")
    local pedestalCount = plot:Save("Pedestals")::number
    local pedestalData = plot:Save("PedestalData")::DefaultStats.PedestalData

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
    else
        TogglePedestal(model, true)

        if pedestalData[tostring(pedestalId)] then
            buyFrame.Visible = false
            upgradeFrame.Visible = true
            placeFrame.Visible = false
        else
            buyFrame.Visible = false
            upgradeFrame.Visible = false
            placeFrame.Visible = true
        end
    end
end

ClientPlot.Created:Connect(function(plot: ClientPlot.Type)
    local model = plot:WaitModel()
    local pedestals = model:WaitForChild("Pedestals")::Model

    for _, child in pedestals:GetChildren() do
        UpdatePedestal(plot, child::Model)
    end

    plot:SaveChanged("Pedestals"):Connect(function(newCount: number)
        print("Pedestals changed", newCount)
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
        end
    end)

    plot:SaveChanged("PedestalData"):Connect(function(newData: DefaultStats.PedestalData)
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
        end
    end)
end)