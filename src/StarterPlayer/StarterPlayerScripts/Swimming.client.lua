--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local FishCmds = require(game.ReplicatedStorage.Game.Library.Client.FishCmds)

local LOCAL_PLAYER = Players.LocalPlayer

local waterParts: {Instance} = {}

local function refreshWater()
    waterParts = CollectionService:GetTagged("Water")
end

refreshWater()
CollectionService:GetInstanceAddedSignal("Water"):Connect(refreshWater)
CollectionService:GetInstanceRemovedSignal("Water"):Connect(refreshWater)

local currentHumanoid: Humanoid? = nil
local currentHRP: BasePart? = nil
local isSwimming = false
local swim: BodyVelocity? = nil
local nextSwimEnableAt = 0

local function onCharacterAdded(character: Model)
    currentHumanoid = character:WaitForChild("Humanoid")::Humanoid
    currentHRP = character:WaitForChild("HumanoidRootPart")::BasePart
    isSwimming = false
    if swim then swim:Destroy() swim = nil end
end

if LOCAL_PLAYER.Character then onCharacterAdded(LOCAL_PLAYER.Character) end
LOCAL_PLAYER.CharacterAdded:Connect(onCharacterAdded)

local function setSwimmingEnabled(enabled: boolean)
    local humanoid = currentHumanoid
    if not humanoid then return end
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not enabled)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not enabled)
end

RunService.RenderStepped:Connect(function()
    local humanoid = currentHumanoid
    local hrp = currentHRP
    if not humanoid or not hrp then return end

    if isSwimming and (LOCAL_PLAYER:GetAttribute("Dead") or LOCAL_PLAYER:GetAttribute("Flying")) then
        if swim then swim:Destroy() swim = nil end
        setSwimmingEnabled(false)
        nextSwimEnableAt = os.clock() + 0.2
        isSwimming = false
        return
    end

    -- Nothing to test against
    if #waterParts == 0 then
        if isSwimming then
            if swim then swim:Destroy() swim = nil end
            setSwimmingEnabled(false)
            nextSwimEnableAt = os.clock() + 0.2
            isSwimming = false
        end
        return
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = waterParts

    local boxSize = hrp.Size + Vector3.new(2, 2, 2)
    local results = workspace:GetPartBoundsInBox(hrp.CFrame, boxSize, params)
    local inWater = results and #results > 0 or false

    if inWater then
        if (not isSwimming) and os.clock() >= nextSwimEnableAt then
            setSwimmingEnabled(true)
            if not swim then swim = Instance.new("BodyVelocity") end
            local s = swim :: BodyVelocity
            s.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            s.Parent = hrp
            isSwimming = true
        end
    else
        if isSwimming then
            if swim then swim:Destroy() swim = nil end
            setSwimmingEnabled(false)
            nextSwimEnableAt = os.clock() + 0.2
            isSwimming = false
        end
    end

    if isSwimming and swim then
        local s = swim :: BodyVelocity
        local upBoost = if UserInputService:IsKeyDown(Enum.KeyCode.Space) then 6 else 0
        s.Velocity = (humanoid.MoveDirection * humanoid.WalkSpeed + Vector3.new(0, 3 + upBoost, 0)) * FishCmds.GetCurrentSpeedModifier()
    end

    local camera = workspace.CurrentCamera
    local cameraResults = workspace:GetPartBoundsInBox(camera.CFrame, Vector3.new(1, 1, 1), params)
    local cameraInWater = cameraResults and #cameraResults > 0 or false
    local topLayer = workspace:WaitForChild("__THINGS"):FindFirstChild("TopLayer")::BasePart
        if topLayer then
            topLayer.Transparency = cameraInWater and 0.6 or 1
        end
end)


