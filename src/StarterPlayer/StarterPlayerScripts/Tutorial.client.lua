--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientPlot = require(ReplicatedStorage.Plot.ClientPlot)
local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local _Functions = require(ReplicatedStorage.Library.Functions)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Network = require(ReplicatedStorage.Library.Client.Network)
local PlotTypes = require(ReplicatedStorage.Game.Library.Types.Plots)

local DISABLE_IN_STUDIO = false

local localPlayer = Players.LocalPlayer

local function isStudio(): boolean
    return RunService:IsStudio()
end

local function getTutorialSave()
    return Save.Get()
end

local function createOrGetBeam(): Beam
    local character = localPlayer.Character
    if not character then
        localPlayer.CharacterAdded:Wait()
        character = localPlayer.Character
    end
    local hrp = character and character:WaitForChild("HumanoidRootPart") :: BasePart
    local a0 = hrp:FindFirstChild("TutorialBeamAttachment0")
    if not a0 then
        a0 = Instance.new("Attachment")
        a0.Name = "TutorialBeamAttachment0"
        a0.Parent = hrp
    end
    local beam = hrp:FindFirstChild("TutorialBeam") :: any
    if not (beam and beam:IsA("Beam")) then
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        local template = assets and assets:FindFirstChild("TutorialBeam")
        if template and template:IsA("Beam") then
            local cloned = template:Clone()
            cloned.Name = "TutorialBeam"
            cloned.Attachment0 = a0
            cloned.Parent = hrp
            beam = cloned
        else
            -- Fallback if the asset is missing
            local newBeam = Instance.new("Beam")
            newBeam.Name = "TutorialBeam"
            newBeam.FaceCamera = true
            newBeam.Width0 = 0.2
            newBeam.Width1 = 0.2
            newBeam.Transparency = NumberSequence.new(0.1)
            newBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
            newBeam.Attachment0 = a0
            newBeam.Parent = hrp
            beam = newBeam
        end
    end
    return beam
end

local function pointBeamToWorldPosition(targetPos: Vector3)
    local character = localPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
    if not hrp then return end
    local beam = createOrGetBeam()
    -- Create/position attachment1 at target position
    local a1Inst = hrp:FindFirstChild("TutorialBeamAttachment1")
    if not a1Inst or not a1Inst:IsA("Attachment") then
        local newA1 = Instance.new("Attachment")
        newA1.Name = "TutorialBeamAttachment1"
        newA1.Parent = hrp
        a1Inst = newA1
    end
    -- We cannot place attachments in world space directly, so create an adornment part to host it
    local holderInst = workspace:FindFirstChild("_TutorialBeamHolder")
    if not holderInst or not holderInst:IsA("BasePart") then
        local newHolder = Instance.new("Part")
        newHolder.Name = "_TutorialBeamHolder"
        newHolder.Anchored = true
        newHolder.CanCollide = false
        newHolder.Transparency = 1
        newHolder.Size = Vector3.new(0.2, 0.2, 0.2)
        newHolder.Parent = workspace
        holderInst = newHolder
    end
    local holderPart: BasePart = holderInst :: BasePart
    holderPart.CFrame = CFrame.new(targetPos)
    local attInst = holderPart:FindFirstChild("Target")
    if not attInst or not attInst:IsA("Attachment") then
        local newAtt = Instance.new("Attachment")
        newAtt.Name = "Target"
        newAtt.Parent = holderPart
        attInst = newAtt
    end
    beam.Attachment1 = attInst :: Attachment
    beam.Enabled = true
end

local function destroyBeam()
	local character = localPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local beam = hrp:FindFirstChild("TutorialBeam")
	if beam and beam:IsA("Beam") then
		beam.Enabled = false
		beam:Destroy()
	end
	local a0 = hrp:FindFirstChild("TutorialBeamAttachment0")
	if a0 and a0:IsA("Attachment") then a0:Destroy() end
	local a1 = hrp:FindFirstChild("TutorialBeamAttachment1")
	if a1 and a1:IsA("Attachment") then a1:Destroy() end
	local holder = workspace:FindFirstChild("_TutorialBeamHolder")
	if holder and holder:IsA("BasePart") then holder:Destroy() end
end

local function getClosestPointOnPart(part: BasePart, point: Vector3): Vector3
    local rel = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    local clamped = Vector3.new(math.clamp(rel.X, -half.X, half.X), math.clamp(rel.Y, -half.Y, half.Y), math.clamp(rel.Z, -half.Z, half.Z))
    return part.CFrame:PointToWorldSpace(clamped)
end

local function distance(a: Vector3, b: Vector3): number
    return (a - b).Magnitude
end

local function findNearestClownFish(fromPos: Vector3): Model?
    local root = workspace:FindFirstChild("__THINGS")
    local fishFolder = root and root:FindFirstChild("SwimmingFish")
    if not fishFolder then return nil end
    local closest: Model? = nil
    local closestD = math.huge
    for _, inst in ipairs(fishFolder:GetDescendants()) do
        if inst:IsA("Model") and inst.Name == "Clown Fish" then
            local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            if primary then
                local d = distance(primary.Position, fromPos)
                if d < closestD then
                    closest = inst
                    closestD = d
                end
            end
        end
    end
    return closest
end

local function zGreaterThan(a: Vector3, b: Vector3): boolean
    return a.Z > b.Z
end

local function withinRadius(pos: Vector3, target: Vector3, r: number): boolean
    return (pos - target).Magnitude <= r
end

local function waitForGoToWater(): BasePart
    local inter = workspace:WaitForChild("Interact"):WaitForChild("Tutorial")
    return inter:WaitForChild("GoToWater") :: BasePart
end

local function tutorialMain()
    if isStudio() and DISABLE_IN_STUDIO then return end
    local stats = getTutorialSave()
    if not stats or stats.FinishedTutorial == true then return end

    local goToWater = waitForGoToWater()

    local state: string = "GoToWater"
    local trackedFish: Model? = nil
    local pedestalTargetId: number? = nil
    local nextPedestalId: number? = nil

    -- Tutorial GUI setup
    local tutorialGui = GUI.Tutorial()
    tutorialGui.Enabled = true
    print(tutorialGui.Enabled)
    task.delay(2, function()
        print(tutorialGui.Enabled)
    end)
    local messageLabel: TextLabel? = tutorialGui:FindFirstChild("Frame") and tutorialGui.Frame:FindFirstChild("Message") :: TextLabel?
    if messageLabel and messageLabel:IsA("TextLabel") then
        messageLabel.Text = ""
    end

    local currentTyperCancel: (() -> ())? = nil
    local function typeMessage(text: string)
        if currentTyperCancel then currentTyperCancel() currentTyperCancel = nil end
        if not messageLabel or not messageLabel:IsA("TextLabel") then return end
        messageLabel.Text = ""
        local cancelled = false
        currentTyperCancel = function() cancelled = true end
        task.spawn(function()
            local out = ""
            for i = 1, #text do
                if cancelled then return end
                out ..= string.sub(text, i, i)
                messageLabel.Text = out
                task.wait(0.075)
            end
        end)
    end

    local lastMessagedState: string? = nil
    local beamUpdater
    beamUpdater = RunService.RenderStepped:Connect(function()
        local character = localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
        if not hrp then return end
        local playerPos = hrp.Position

        -- Only (re)type the message when the state changes
        if state ~= lastMessagedState then
            if state == "GoToWater" then
                typeMessage("Go to the water!")
            elseif state == "FindClownFish" then
                typeMessage("Catch a Clown Fish!")
            elseif state == "ReturnToWaterWithFish" then
                typeMessage("Return to safety!")
            elseif state == "FindEmptyPedestal" then
                typeMessage("Place your fish in your base!")
            elseif state == "PointClaim" then
                typeMessage("Claim money from your fish!")
            elseif state == "PointNextPedestalNameplate" then
                typeMessage("Buy the next platform so you can catch more fish!")
            elseif state == "Complete" then
                typeMessage("Catch more fish now!")
            end
            lastMessagedState = state
        end

        if state == "GoToWater" then
            local closest = getClosestPointOnPart(goToWater, playerPos)
            pointBeamToWorldPosition(closest)
            if withinRadius(playerPos, goToWater.Position, 5) or zGreaterThan(playerPos, goToWater.Position) then
                state = "FindClownFish"
            end
        elseif state == "FindClownFish" then
            if not trackedFish or not trackedFish.Parent then
                trackedFish = findNearestClownFish(playerPos)
            end
            if trackedFish then
                local part = trackedFish.PrimaryPart or trackedFish:FindFirstChildWhichIsA("BasePart")
                if part then
                    pointBeamToWorldPosition(part.Position)
                end
            end

            local carrying = localPlayer:GetAttribute("CarryingFishId")
            if carrying and zGreaterThan(playerPos, goToWater.Position) then
                state = "ReturnToWaterWithFish"
            elseif (not withinRadius(playerPos, goToWater.Position, 5)) and (not zGreaterThan(playerPos, goToWater.Position)) then
                state = "GoToWater"
            end
        elseif state == "ReturnToWaterWithFish" then
            local closest = getClosestPointOnPart(goToWater, playerPos)
            pointBeamToWorldPosition(closest)
            local carrying = localPlayer:GetAttribute("CarryingFishId")
            local flying = localPlayer:GetAttribute("Flying")
            if (not carrying or flying) and zGreaterThan(playerPos, goToWater.Position) then
                state = "FindClownFish"
            elseif not zGreaterThan(playerPos, goToWater.Position) then
                -- Dropped below water; wait for TutorialState->1 or 5s
                local deadline = time() + 5
                while time() < deadline do
                    local s = getTutorialSave()
                    if s and s.TutorialState == 1 then break end
                    task.wait(0.25)
                end
                state = "FindEmptyPedestal"
            end
        elseif state == "FindEmptyPedestal" then
            local plot = ClientPlot.GetLocal()
            if not plot then return end
            local pedestals = plot:Save("Pedestals") :: number
            local fishMap = plot:Save("Fish") :: {[string]: any}
            pedestalTargetId = nil
            for i = 1, pedestals do
                local key = tostring(i)
                if not fishMap[key] then
                    pedestalTargetId = i
                    break
                end
            end
            if not pedestalTargetId then
                state = "Done"
                return
            end
            local plotModel = plot:WaitModel()
            local pedsFolder = plotModel:WaitForChild("Pedestals")
            local pedModel = pedsFolder:FindFirstChild(tostring(pedestalTargetId))
            if pedModel then
                local nameplate = pedModel:FindFirstChild("Nameplate") :: BasePart
                if nameplate then
                    pointBeamToWorldPosition(nameplate.Position)
                end
            end
            -- Wait until this pedestal gets fish data
            task.spawn(function()
                while true do
                    task.wait(0.1)
                    local fishNow = plot:Save("Fish")
                    if fishNow and (fishNow[tostring(pedestalTargetId :: number)] ~= nil) then
                        state = "PointClaim"
                        break
                    end
                end
            end)
        elseif state == "PointClaim" then
            local plot = ClientPlot.GetLocal()
            if not plot then return end
            local plotModel = plot:WaitModel()
            local pedsFolder = plotModel:WaitForChild("Pedestals")
            local pedModel = pedsFolder:FindFirstChild(tostring(pedestalTargetId :: number))
            if pedModel then
                local claim = pedModel:FindFirstChild("Claim") :: BasePart
                if claim then
                    pointBeamToWorldPosition(claim.Position)
                end
            end
            nextPedestalId = (pedestalTargetId :: number) + 1
            local cost = PlotTypes.PedestalCost(nextPedestalId::number)
            task.spawn(function()
                while true do
                    task.wait(0.1)
                    local money = plot:Save("Money")
                    if type(money) == "number" and cost and money >= cost then
                        state = "PointNextPedestalNameplate"
                        break
                    end
                end
            end)
        elseif state == "PointNextPedestalNameplate" then
            local plot = ClientPlot.GetLocal()
            if not plot then return end
            local plotModel = plot:WaitModel()
            local pedsFolder = plotModel:WaitForChild("Pedestals")
            local pedModel = pedsFolder:FindFirstChild(tostring(nextPedestalId :: number))
            if pedModel then
                local nameplate = pedModel:FindFirstChild("Nameplate") :: BasePart
                if nameplate then
                    pointBeamToWorldPosition(nameplate.Position)
                end
            end
            local initialCount = plot:Save("Pedestals") :: number
            task.spawn(function()
                while true do
                    task.wait(0.1)
                    local count = plot:Save("Pedestals")
                    if type(count) == "number" and count > initialCount then
                        state = "Complete"
                        break
                    end
                end
            end)
        elseif state == "Complete" then
            print("YOU DID IT!")
            Network.Fire("SetFinishedTutorial")
            destroyBeam()
            task.delay(3, function()
                -- Show a final tip after the completion message sits for 3s
                typeMessage("Buy tools to be faster in the water!")
                task.delay(6, function()
                    -- End tutorial and mark as finished
                    if tutorialGui and tutorialGui:IsA("ScreenGui") then
                        tutorialGui.Enabled = false
                    end
                end)
            end)
            if beamUpdater then beamUpdater:Disconnect() end
        end
    end)
end

task.spawn(function()
    local save = Save.Get()
    if not save then
        local conn
        conn = Save.SaveAdded:Connect(function()
            if conn then conn:Disconnect() end
            tutorialMain()
        end)
    else
        tutorialMain()
    end
end)


