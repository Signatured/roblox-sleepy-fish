--!strict

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.Library.Audio)

local BASE_FOV = 70
local TARGET_FOV = 55

local activePrompt: ProximityPrompt? = nil
local holdTween: Tween? = nil
local startTime: number = 0

-- Optional: set an attribute "RiserSoundId" / "RiserSoundVolume" on the prompt from the server
local DEFAULT_RISER_ID = "rbxassetid://95437214341584" -- fallback if attribute not provided
local DEFAULT_RISER_VOL = 0.5

local function isFishPrompt(prompt: ProximityPrompt): boolean
    if not prompt or not prompt.Parent then return false end
    if prompt.ActionText ~= "Pick Up" then return false end
    local ancestor = prompt.Parent:FindFirstAncestorOfClass("Model")
    if not ancestor then return false end
    return ancestor:GetAttribute("UID") ~= nil or CollectionService:HasTag(ancestor, "SwimmingFish")
end

local function cancelTween()
    if holdTween then
        pcall(function() holdTween:Cancel() end)
        holdTween = nil
    end
end

local function tweenFov(toFov: number, duration: number, easing: Enum.EasingStyle)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    cancelTween()
    local tween = TweenService:Create(cam, TweenInfo.new(math.max(0, duration), easing or Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { FieldOfView = toFov })
    holdTween = tween
    tween:Play()
end

-- When the player begins holding a fish pickup prompt
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
    if not isFishPrompt(prompt) then return end
    activePrompt = prompt
    startTime = Workspace:GetServerTimeNow()
    local cam = Workspace.CurrentCamera
    if cam then
        -- Animate inward over the hold duration (fallback to 1.0 if zero)
        local duration = prompt.HoldDuration
        if typeof(duration) ~= "number" or duration <= 0 then duration = 1.0 end
        tweenFov(TARGET_FOV, duration, Enum.EasingStyle.Linear)
    end

    -- Start riser audio locally (attach to this script so only the local client hears it)
    local riserId = (prompt:GetAttribute("RiserSoundId") :: string) or DEFAULT_RISER_ID
    local riserVol = (prompt:GetAttribute("RiserSoundVolume") :: number) or DEFAULT_RISER_VOL
    Audio.Play(riserId, script, 1, riserVol, 100, true)
end)

-- When the player cancels holding mid-way
ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt: ProximityPrompt)
    if activePrompt ~= prompt then return end
    local elapsed = math.max(0, Workspace:GetServerTimeNow() - startTime)
    activePrompt = nil
    -- Drain back to base FOV over half the time spent holding
    local drainTime = math.max(0.05, elapsed / 2)
    tweenFov(BASE_FOV, drainTime, Enum.EasingStyle.Linear)

    -- Stop riser audio immediately (find and stop looped sound started on hold-began)
    local riserId = (prompt:GetAttribute("RiserSoundId") :: string) or DEFAULT_RISER_ID
    for _, child in ipairs(script:GetChildren()) do
        if child:IsA("Sound") and child.SoundId == riserId then
            pcall(function() child:Stop() end)
            child:Destroy()
        end
    end
end)

-- On successful trigger (fish claimed)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, _player)
    if not isFishPrompt(prompt) then return end
    activePrompt = nil
    -- Snap to completion moment, then ease back to base over 0.5s (Sine Out)
    tweenFov(BASE_FOV, 0.5, Enum.EasingStyle.Sine)

    -- Stop riser so the success SFX can play cleanly
    local riserId = (prompt:GetAttribute("RiserSoundId") :: string) or DEFAULT_RISER_ID
    for _, child in ipairs(script:GetChildren()) do
        if child:IsA("Sound") and child.SoundId == riserId then
            pcall(function() child:Stop() end)
            child:Destroy()
        end
    end
end)


