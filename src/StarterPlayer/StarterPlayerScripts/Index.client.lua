--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Save = require(ReplicatedStorage.Library.Client.Save)
local ExistCountCmds = require(ReplicatedStorage.Game.Library.Client.ExistCountCmds)
local Functions = require(ReplicatedStorage.Library.Functions)
local ScreenResolution = require(ReplicatedStorage.Library.Client.ScreenResolution)

local SELECTED_IMG = "rbxassetid://85004105467436"
local UNSELECTED_IMG = "rbxassetid://72752195568291"

local currentCategory: FishTypes.fish_type = "Normal"

local resolutionSettings = {
	{
		ResolutionThreshold = 0.65, 
		PerRow = 3,
		Padding = UDim2.new(0.01, 0, 0.01, 0)
	},
	{
		ResolutionThreshold = 1.2,
		PerRow = 4,
		Padding = UDim2.new(0.01, 0, 0.01, 0)
	},
	{ 
		ResolutionThreshold = math.huge, 
		PerRow = 4,
		Padding = UDim2.new(0.01, 0, 0.01, 0)
	}
}

local function getGui()
    local indexGui = GUI.Index()
    return indexGui
end

local function sortFishByMps(): {FishTypes.dir_schema}
    local items = {}
    for _, dir in pairs(Directory.Fish) do
        table.insert(items, dir)
    end
    table.sort(items, function(a, b)
        return (a.MoneyPerSecond or 0) > (b.MoneyPerSecond or 0)
    end)
    return items
end

local function setCategoryButtons(root: Instance, onCategoryChanged: () -> ())
    local side = root:FindFirstChild("SideFrame")
    if not side or not side:IsA("Frame") then return end
    local function wire(buttonName: string, cat: FishTypes.fish_type)
        local btn = side:FindFirstChild(buttonName)
        if btn and btn:IsA("ImageButton") then
            ButtonFX(btn)
            btn.Activated:Connect(function()
                currentCategory = cat
                btn.Image = SELECTED_IMG
                for _, other in ipairs({"Normal","Gold","Rainbow","Shiny"}) do
                    if other ~= buttonName then
                        local ob = side:FindFirstChild(other)
                        if ob and ob:IsA("ImageButton") then
                            ob.Image = UNSELECTED_IMG
                        end
                    end
                end
                task.defer(function()
                    onCategoryChanged()
                end)
            end)
        end
    end
    wire("Normal","Normal")
    wire("Gold","Gold")
    wire("Rainbow","Rainbow")
    wire("Shiny","Shiny")
end

local function realRender()
    local indexGui = getGui()
    if not indexGui then return end
    local frame = indexGui:FindFirstChild("Frame")
    local main = frame and frame:FindFirstChild("MainFrame")
    if not (frame and main and main:IsA("Frame")) then return end
    local contentFrame = main:FindFirstChild("Content")
    if not (contentFrame and contentFrame:IsA("Frame")) then return end
    local itemsFrame = contentFrame:FindFirstChild("Items")
    if not (itemsFrame and itemsFrame:IsA("ScrollingFrame")) then return end
    local template = itemsFrame:FindFirstChild("IndexCard")
    if not (template and template:IsA("Frame")) then return end
    template.Visible = false

    -- clear existing
    for _, child in ipairs(itemsFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == "IndexCard" and child ~= template then
            child:Destroy()
        end
    end

    -- default selection visuals
    local side = frame:FindFirstChild("SideFrame")
    if side and side:IsA("Frame") then
        for _, n in ipairs({"Normal","Gold","Rainbow","Shiny"}) do
            local b = side:FindFirstChild(n)
            if b and b:IsA("ImageButton") then
                b.Image = (n == currentCategory) and SELECTED_IMG or UNSELECTED_IMG
            end
            if b and b:IsA("ImageButton") then ButtonFX(b) end
        end
    end

    local fishList = sortFishByMps()
    local counts = ExistCountCmds.GetAll() or {}

    local function renderIntoViewport(view: ViewportFrame, modelTemplate: Model, dir: FishTypes.dir_schema)
        -- Clear previous
        for _, c in ipairs(view:GetChildren()) do c:Destroy() end
        view.Ambient = Color3.fromRGB(200, 200, 200)
        view.LightColor = Color3.fromRGB(255, 255, 255)

        local cam = Instance.new("Camera")
        cam.Parent = view
        view.CurrentCamera = cam

        -- Use a container model to compute bounds
        local container = Instance.new("Model")
        container.Name = "ViewportWorld"
        container.Parent = view

        local clone = modelTemplate:Clone()
        clone.Parent = container

        local bboxCF, bboxSize = container:GetBoundingBox()
        local target = bboxCF.Position
        local indexOffset = dir.IndexOffset or 0
        local indexPositionOffset = dir.IndexPositionOffset or Vector3.new(0, 0, 0)
        -- Compute a camera position directly in front of the model by half Z + 5 studs
        local camPos = target + bboxCF.LookVector * (bboxSize.Z + indexOffset)
        -- Pivot the model so its forward (LookVector) faces the camera position
        local modelFaceCF = CFrame.lookAt(target, camPos, bboxCF.UpVector)
        local rotationOffset = dir.IndexRotationOffset or Vector3.new(0, 0, 0)
        -- Rotate fish 90 degrees around Y axis for desired presentation
        container:PivotTo(modelFaceCF * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(rotationOffset.X, rotationOffset.Y, rotationOffset.Z))
        -- Finally, position the camera to look at the model head-on
        cam.CFrame = CFrame.lookAt(camPos, target, bboxCF.UpVector) * CFrame.new(indexPositionOffset.X, indexPositionOffset.Y, indexPositionOffset.Z)

        clone:SetAttribute("BobAmplitude", 0.25)
        clone:SetAttribute("SwayAmplitude", 0.25)
        clone:SetAttribute("RollMaxDeg", 5)
        clone:SetAttribute("YawMaxDeg", 5)
        clone:AddTag("SwimmingFish")
    end

    for _, dir in ipairs(fishList) do
        local fishId = dir._id
        local display = dir.DisplayName or fishId
        local countForId = counts[fishId]
        local countVal = 0
        if countForId then
            if currentCategory == "Normal" then countVal = countForId.Normal
            elseif currentCategory == "Gold" then countVal = countForId.Gold
            elseif currentCategory == "Shiny" then countVal = countForId.Shiny
            elseif currentCategory == "Rainbow" then countVal = countForId.Rainbow end
        end

        local card = template:Clone()
        card.Visible = true
        local nameLabel = card:FindFirstChild("Name")
        local existLabel = card:FindFirstChild("Exist")
        local viewport = card:FindFirstChild("ViewportFrame")
        local hasSeen = countVal > 0
        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = display
            nameLabel.Visible = hasSeen
        end
        if existLabel and existLabel:IsA("TextLabel") then
            existLabel.Text = string.format("%d Exist", countVal)
            existLabel.Visible = hasSeen
        end
        -- Render the fish model into the viewport
        if viewport and viewport:IsA("ViewportFrame") then
            local modelTemplate = dir._script and dir._script:FindFirstChild("Model")
            if modelTemplate and modelTemplate:IsA("Model") then
                renderIntoViewport(viewport, modelTemplate, dir)
            end
        end
        card.Parent = itemsFrame
    end

    -- task.spawn(function()
	-- 	while true do
	-- 		if TabController.GetCurrentTab() ~= "Index" then break end
	-- 		Functions.AutoGridLayout(itemsFrame, resolutionSettings, true)
	-- 		task.wait(0.1)
	-- 	end
	-- end)
    task.delay(0.1, function()
        Functions.AutoGridLayout(itemsFrame, resolutionSettings, true)()
        -- Functions.UpdateCanvasSize(itemsFrame)
    end)
end

local initialized = false

local function setup()
    local gui = getGui()
    if not gui then return end
    local frame = gui:FindFirstChild("Frame")
    if not frame then return end
    setCategoryButtons(frame, realRender)
    currentCategory = "Normal"
    realRender()
    initialized = true
end

ScreenResolution.Changed:Connect(function()
    if initialized then
        task.delay(0.1, function()
            local indexGui = getGui()
            if not indexGui then return end
            local frame = indexGui:FindFirstChild("Frame")
            local main = frame and frame:FindFirstChild("MainFrame")
            if not (frame and main and main:IsA("Frame")) then return end
            local contentFrame = main:FindFirstChild("Content")
            if not (contentFrame and contentFrame:IsA("Frame")) then return end
            local itemsFrame = contentFrame:FindFirstChild("Items")

            Functions.AutoGridLayout(itemsFrame, resolutionSettings, true)()
        end)
    end
end)

-- Initial and reactive wiring
Save.SaveAdded:Connect(function()
    if TabController.GetCurrentTab and TabController.GetCurrentTab() == "Index" then
        setup()
    end
end)

Save.Fired(function(key: string, _value: any)
    if key == "Index" then
        if TabController.GetCurrentTab and TabController.GetCurrentTab() == "Index" then
            realRender()
        end
    end
end)

-- Open/close wiring via TabController
TabController.Opened:Connect(function(tabId: string)
    if tabId == "Index" then
        if not initialized then
            setup()
        else
            realRender()
        end
    end
end)

-- If save already ready and tab is open
if Save.Get() and TabController.GetCurrentTab and TabController.GetCurrentTab() == "Index" then
    setup()
end


