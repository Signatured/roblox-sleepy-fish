--!strict

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local DefaultStats = require(game.ReplicatedStorage.Game.Modules.DefaultStats)

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

function SetupPedestal(plot: ClientPlot.Type, model: Model)
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

function UpdatePedestal(plot: ClientPlot.Type, model: Model)
    
end

ClientPlot.Created:Connect(function(plot: ClientPlot.Type)
    local model = plot:WaitModel()
    local pedestals = model:WaitForChild("Pedestals")::Model

    for _, child in pedestals:GetChildren() do
        SetupPedestal(plot, child::Model)
    end

    plot:SaveChanged("Pedestals"):Connect(function(newCount: number)
        for _, child in pedestals:GetChildren() do
            SetupPedestal(plot, child::Model)
        end
    end)

    plot:SaveChanged("PedestalData"):Connect(function(newData: DefaultStats.PedestalData)
        for _, child in pedestals:GetChildren() do
            SetupPedestal(plot, child::Model)
        end
    end)
end)