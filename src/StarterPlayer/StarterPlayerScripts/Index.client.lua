--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Functions = require(ReplicatedStorage.Library.Functions)
local ScreenResolution = require(ReplicatedStorage.Library.Client.ScreenResolution)
local ExistCountCmds = require(ReplicatedStorage.Game.Library.Client.ExistCountCmds)

local SELECTED_IMG = "rbxassetid://85004105467436"
local UNSELECTED_IMG = "rbxassetid://72752195568291"

local currentCategory: FishTypes.fish_type | "BloodMoon" | "Galaxy" | "Spooky" = "Normal"

local categories = {"Normal","Gold","Rainbow","Shiny","BloodMoon","Galaxy","Spooky"}

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

local function GetMutationId(mutation: string?): string?
	if not mutation then
		return nil
	end

    if mutation == "BloodMoon" then
        return "Bloodfish"
    else
        local mutationDir = Directory.Mutations[mutation]
        if mutationDir then
            if mutationDir._id == "Bloodfish" then -- Bloodfish was done weird originally, so we need to convert it to the new format
                return "BloodMoon"
            else
                return mutationDir._id
            end
        end
    end
    return nil
end

local function getGui()
    local indexGui = GUI.Index()
    return indexGui
end

local function sortFishByMps(): {FishTypes.dir_schema}
    local items = {}
    for _, dir in pairs(Directory.Fish) do
        if dir.Rarity and dir.Rarity._id == "Exclusive" then
            continue
        end
        table.insert(items, dir)
    end
    table.sort(items, function(a, b)
        return (a.MoneyPerSecond or 0) < (b.MoneyPerSecond or 0)
    end)
    return items
end

local function setCategoryButtons(root: Instance, onCategoryChanged: () -> ())
    local side = root:FindFirstChild("SideFrame")
    if not side or not side:IsA("Frame") then return end
    local function wire(buttonName: string, cat: FishTypes.fish_type | "BloodMoon" | "Galaxy" | "Spooky")
        local btn = side:FindFirstChild(buttonName)
        if btn and btn:IsA("ImageButton") then
            ButtonFX(btn)
            btn.Activated:Connect(function()
                currentCategory = cat
                btn.Image = SELECTED_IMG
                for _, other in ipairs(categories) do
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
    wire("BloodMoon","BloodMoon")
    wire("Galaxy","Galaxy")
    wire("Spooky","Spooky")
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
        for _, n in ipairs(categories) do
            local b = side:FindFirstChild(n)
            if b and b:IsA("ImageButton") then
                b.Image = (n == currentCategory) and SELECTED_IMG or UNSELECTED_IMG
            end
            if b and b:IsA("ImageButton") then ButtonFX(b) end
        end
    end

    local fishList = sortFishByMps()
    local saveForIndex = Save.Get()
    local playerIndex = (saveForIndex and saveForIndex.Index) or {}

    local function renderIntoViewport(view: ViewportFrame, modelTemplate: Model, dir: FishTypes.dir_schema, hasSeen: boolean)
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
        
        -- Apply Bloodfish visual effect for BloodMoon category
        local mutationId = GetMutationId(currentCategory)
        if mutationId and hasSeen then  
            local mutationDir = Directory.Mutations[mutationId]
            if mutationDir then
                mutationDir.ApplyToModel(clone)
            end
        end

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

        if not hasSeen then
            for _, inst in ipairs(clone:GetDescendants()) do
                if inst:IsA("BasePart") then
                    inst.Color = Color3.new(0, 0, 0)
                end
            end
        end
    end

    for _, dir in ipairs(fishList) do
        local fishId = dir._id
        local display = dir.DisplayName or fishId
        local entry = playerIndex[fishId]
        local hasSeen = false
        if entry then
            if currentCategory == "Normal" then hasSeen = entry.Normal == true
            elseif currentCategory == "Gold" then hasSeen = entry.Gold == true
            elseif currentCategory == "Shiny" then hasSeen = entry.Shiny == true
            elseif currentCategory == "Rainbow" then hasSeen = entry.Rainbow == true
            elseif currentCategory == "BloodMoon" then hasSeen = entry.BloodMoon == true
            elseif currentCategory == "Galaxy" then hasSeen = entry.Galaxy == true
            elseif currentCategory == "Spooky" then hasSeen = entry.Spooky == true
            end
        end
        local countVal = 0
        if hasSeen then
            local mutationId = GetMutationId(currentCategory)

            if mutationId then
                countVal = ExistCountCmds.GetMutationCount(fishId, mutationId)
            else
                countVal = ExistCountCmds.GetByIdAndType(fishId, currentCategory)
            end
        end
        local countString = Functions.Commas(countVal)

        local card = template:Clone()
        card.Visible = true
        local nameLabel = card:FindFirstChild("Name")
        local existLabel = card:FindFirstChild("Exist")
        local viewport = card:FindFirstChild("ViewportFrame")
        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = display
            nameLabel.Visible = true
        end
        if existLabel and existLabel:IsA("TextLabel") then
            if hasSeen then
                -- if currentCategory == "BloodMoon" then
                --     existLabel.Text = `{countString} Exist`
                -- elseif currentCategory == "Galaxy" then
                --     existLabel.Text = `{countString} Exist`
                -- else
                --     existLabel.Text = `{countString} Exist`
                -- end
                existLabel.Text = `Discovered!`
            else
                existLabel.Text = "???"
                existLabel.TextColor3 = Color3.new(1, 1, 1)
            end
            existLabel.Visible = true
        end
        -- Set gradient color to rarity color
        local bg = card:FindFirstChild("Background")
        if bg and bg:IsA("ImageLabel") then
            local grad = bg:FindFirstChild("UIGradient")
            local rarityName = (dir.Rarity and dir.Rarity.DisplayName) or ""
            if rarityName == "Mythical" then
                if grad and grad:IsA("UIGradient") then
                    grad:Destroy()
                end
                local templateFolder = ReplicatedStorage:FindFirstChild("Assets")
                local gradientTemplate = templateFolder and templateFolder:FindFirstChild("RainbowGradientWrapped")
                if gradientTemplate and gradientTemplate:IsA("UIGradient") then
                    local rainbow = gradientTemplate:Clone()
                    rainbow.Parent = bg
                    Functions.GradientScroll(rainbow, 2.5)
                end
            elseif rarityName == "God" then
                if grad and grad:IsA("UIGradient") then
                    grad:Destroy()
                end
                local templateFolder = ReplicatedStorage:FindFirstChild("Assets")
                local gradientTemplate = templateFolder and templateFolder:FindFirstChild("GodGradient")
                if gradientTemplate and gradientTemplate:IsA("UIGradient") then
                    local rainbow = gradientTemplate:Clone()
                    rainbow.Parent = bg
                    Functions.GradientScroll(rainbow, 2.5)
                end
            elseif rarityName == "Secret" then
                if grad and grad:IsA("UIGradient") then
                    grad:Destroy()
                end
                local templateFolder = ReplicatedStorage:FindFirstChild("Assets")
                local gradientTemplate = templateFolder and templateFolder:FindFirstChild("SecretGradient")
                if gradientTemplate and gradientTemplate:IsA("UIGradient") then
                    local rainbow = gradientTemplate:Clone()
                    rainbow.Parent = bg
                    Functions.GradientScroll(rainbow, 2.5)
                end
            else
                if grad and grad:IsA("UIGradient") and dir.Rarity and typeof(dir.Rarity.Color) == "Color3" then
                    local rc = dir.Rarity.Color
                    grad.Color = ColorSequence.new(rc, rc)
                end
            end
        end
        -- Render the fish model into the viewport
        if viewport and viewport:IsA("ViewportFrame") then
            local modelTemplate = dir._script and dir._script:FindFirstChild("Model")
            if modelTemplate and modelTemplate:IsA("Model") then
                renderIntoViewport(viewport, modelTemplate, dir, hasSeen)
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