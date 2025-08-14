--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LOCAL_PLAYER = Players.LocalPlayer

local waterParts: {Instance} = {}

local function rebuildWaterList()
    waterParts = CollectionService:GetTagged("Water")
end

rebuildWaterList()
CollectionService:GetInstanceAddedSignal("Water"):Connect(function()
    rebuildWaterList()
end)
CollectionService:GetInstanceRemovedSignal("Water"):Connect(function()
    rebuildWaterList()
end)

local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentHRP: BasePart? = nil
local wasInWater = false
local swim: BodyVelocity = nil

local function onCharacterAdded(character: Model)
    currentCharacter = character
    currentHumanoid = character:WaitForChild("Humanoid")::Humanoid
    currentHRP = character:WaitForChild("HumanoidRootPart")::BasePart
    wasInWater = false
end

if LOCAL_PLAYER.Character then
    onCharacterAdded(LOCAL_PLAYER.Character)
end
LOCAL_PLAYER.CharacterAdded:Connect(onCharacterAdded)

RunService.RenderStepped:Connect(function()
    local humanoid = currentHumanoid
    local hrp = currentHRP
    if not humanoid or not hrp then
        return
    end
    if #waterParts == 0 then
        if wasInWater then
            wasInWater = false
            if swim then
                swim:Destroy()
                swim = nil::any
            end
        end
        return
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = waterParts

    local size = hrp.Size + Vector3.new(2, 2, 2)
    local results = workspace:GetPartBoundsInBox(hrp.CFrame, size, params)
    local inWater = results and #results > 0 or false

    if inWater and not wasInWater then
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

        swim = Instance.new("BodyVelocity")
        swim.Parent = hrp
        wasInWater = true
    elseif not inWater and wasInWater then 
        wasInWater = false
        if swim then
            swim:Destroy()
            swim = nil::any
        end
    end

    if inWater and currentHumanoid then
        currentHumanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

       if swim then
        swim.Velocity = currentHumanoid.MoveDirection * currentHumanoid.WalkSpeed + Vector3.new(0,4,0)
       end
    end
end)


