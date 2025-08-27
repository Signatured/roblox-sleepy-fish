--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local FishCmds = require(game.ReplicatedStorage.Game.Library.Client.FishCmds)
local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)
local Functions = require(game.ReplicatedStorage.Library.Functions)
local Audio = require(game.ReplicatedStorage.Library.Audio)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

local LOCAL_PLAYER = Players.LocalPlayer

local waterParts: {Instance} = {}
local waterEnterTimestamp: number? = nil

local function getWaterElapsedSeconds(): number
    local t = waterEnterTimestamp
    if t then
        return os.clock() - t
    end
    return 0
end

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

-- Returns true if the local player owns the "Double Money" gamepass according to their save
local function ownsDoubleMoney(): boolean
    local save = Save.Get()
    if not save then
        return false
    end
    local gp = save.Gamepasses
    if not gp then
        return false
    end
    return gp["Double Money"] == true
end

local function onCharacterAdded(character: Model)
    currentHumanoid = character:WaitForChild("Humanoid")::Humanoid
    currentHRP = character:WaitForChild("HumanoidRootPart")::BasePart
    isSwimming = false
    if swim then swim:Destroy(); swim = nil end
end

if LOCAL_PLAYER.Character then onCharacterAdded(LOCAL_PLAYER.Character); end
LOCAL_PLAYER.CharacterAdded:Connect(onCharacterAdded)

local function setSwimmingEnabled(enabled: boolean)
    local humanoid = currentHumanoid
    if not humanoid then return end
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not enabled)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not enabled)
end

local defaultWalkspeed = 16
RunService.RenderStepped:Connect(function()
    local humanoid = currentHumanoid
    local hrp = currentHRP
    if not humanoid or not hrp then return end

    local thingsFolder = workspace:FindFirstChild("__THINGS")
    local swimUpArea = thingsFolder and thingsFolder:FindFirstChild("SwimUpZone")::BasePart
    local inSwimUpArea = swimUpArea and Functions.IsPositionInPart(hrp.Position, swimUpArea)

    if isSwimming and (LOCAL_PLAYER:GetAttribute("Dead") or LOCAL_PLAYER:GetAttribute("Flying") or LOCAL_PLAYER:GetAttribute("CarpetFlying") or LOCAL_PLAYER:GetAttribute("LocalCarpetFlying")) then
        if swim then swim:Destroy(); swim = nil end
        setSwimmingEnabled(false)
        nextSwimEnableAt = os.clock() + 0.2
        isSwimming = false

        print("stopped swimming")
        return
    end

    if LOCAL_PLAYER:GetAttribute("CarpetFlying") or LOCAL_PLAYER:GetAttribute("LocalCarpetFlying") then
        return
    end

    -- Nothing to test againsta
    if #waterParts == 0 then
        if isSwimming then
            if swim then swim:Destroy(); swim = nil end
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

    -- Track enter/exit timestamps for water
    if inWater then
        if not waterEnterTimestamp then
            waterEnterTimestamp = os.clock()
        end
    else
        if waterEnterTimestamp then
            waterEnterTimestamp = nil
        end
    end

    if inWater then
        if (not isSwimming) and os.clock() >= nextSwimEnableAt then
            setSwimmingEnabled(true)
            if not swim then swim = Instance.new("BodyVelocity") end
            local s = swim :: BodyVelocity
            s.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            s.Parent = hrp
            isSwimming = true
            -- Auto-equip the best coil gadget when entering water
            GadgetCmds.EquipBestCoil()
            -- Play swim start SFX
            Audio.Play("rbxassetid://95038957115197", hrp, nil, 0.2)
        end
    else
        if isSwimming then
            if swim then swim:Destroy(); swim = nil end
            setSwimmingEnabled(false)
            nextSwimEnableAt = os.clock() + 0.2
            isSwimming = false
        end
    end

    if isSwimming and swim then
        local s = swim :: BodyVelocity
        local hasFocus = UserInputService:GetFocusedTextBox() ~= nil
        local helpUpwards = inSwimUpArea and getWaterElapsedSeconds() > 3
        -- Treat Space (keyboard), ButtonA (gamepad), or Humanoid.Jump (mobile jump button) as jump-held
        local jumpHeld = (not hasFocus) and (UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) or humanoid.Jump)
        local upBoost = if (jumpHeld or helpUpwards) then 6 else 0
        local fishMulti = FishCmds.GetCurrentSpeedModifier()
        local currentGadget = GadgetCmds.GetCurrent()
        local gadgetMulti = currentGadget and currentGadget.SpeedMultiplier or 1
        local totalMulti = fishMulti * gadgetMulti
        local ownsDoubleMoney = ownsDoubleMoney()
        s.Velocity = ((humanoid.MoveDirection * (defaultWalkspeed + (ownsDoubleMoney and 3 or 0)) + Vector3.new(0, upBoost, 0)) * totalMulti) + Vector3.new(0, 0.25, 0) -- add 2 to Y to swim up by default
    end

    if isSwimming and (LOCAL_PLAYER:GetAttribute("CarryingFishId") or LOCAL_PLAYER:GetAttribute("ActivePrompt")) then
        GadgetCmds.UnequipMagicCarpet()
    end

    local camera = workspace.CurrentCamera
    local cameraResults = workspace:GetPartBoundsInBox(camera.CFrame, Vector3.new(1, 1, 1), params)
    local cameraInWater = cameraResults and #cameraResults > 0 or false
    local topLayer = workspace:WaitForChild("__THINGS"):FindFirstChild("TopLayer")::BasePart
        if topLayer then
            topLayer.Transparency = cameraInWater and 0.6 or 1
        end
end)

RunService.RenderStepped:Connect(function()
    local humanoid = currentHumanoid
    if not humanoid then return end

    local currentGadget = GadgetCmds.GetCurrent()
    local gadgetMulti = currentGadget and currentGadget.SpeedMultiplier or 1
    local ownsDoubleMoney = ownsDoubleMoney()

    humanoid.WalkSpeed = (defaultWalkspeed * gadgetMulti) + (ownsDoubleMoney and 3 or 0)
end)