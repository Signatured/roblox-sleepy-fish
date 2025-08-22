--!strict

--[[
	Manages the background music, respecting the player's in-game settings.
]]

local _RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local Save = require(ReplicatedStorage.Library.Client.Save)
local Signal = require(ReplicatedStorage.Library.Signal)

local MUSIC_IDS = {
    "rbxassetid://1841647093",
    "rbxassetid://1848354536",
}
local CHASE_MUSIC_IDS = {
    "rbxassetid://1847683491",
	"rbxassetid://76893650686729",
	"rbxassetid://106684853320177"
}
local lastIndex: number? = nil
local defaultVolume = 0.25

local musicSound = Instance.new("Sound")
musicSound.Name = "BackgroundMusic"
musicSound.Looped = true
musicSound.Volume = defaultVolume -- Default volume
musicSound.Parent = SoundService
musicSound.SoundGroup = SoundService:WaitForChild("Music")

local isChaseActive = false
local chaseSound: Sound? = nil
local chasePreloaded: {[string]: Sound} = {}

-- Preload chase music at script load so it's ready instantly when triggered
task.spawn(function()
    if #CHASE_MUSIC_IDS == 0 then return end
    -- Preload all chase tracks to ensure instant playback
    local holder = Instance.new("Folder")
    holder.Name = "__ChasePreloaded"
    holder.Parent = SoundService
    for _, id in ipairs(CHASE_MUSIC_IDS) do
        if typeof(id) == "string" and id ~= "" then
            local s = Instance.new("Sound")
            s.Name = "ChasePreload"
            s.SoundGroup = SoundService:WaitForChild("Music")
            s.SoundId = id
            s.Parent = holder
            pcall(function()
                ContentProvider:PreloadAsync({s})
            end)
            chasePreloaded[id] = s
        end
    end
end)

local function pickNextTrackIndex(): number
    if #MUSIC_IDS == 0 then return 1 end
    if #MUSIC_IDS == 1 then return 1 end
    local idx = math.random(1, #MUSIC_IDS)
    if lastIndex ~= nil and idx == lastIndex then
        idx = (idx % #MUSIC_IDS) + 1
    end
    return idx
end

local function setRandomTrack()
    local idx = pickNextTrackIndex()
    lastIndex = idx
    musicSound.SoundId = MUSIC_IDS[idx]
end

local function updateMusicState()
	local saveData = Save.Get()
	if not saveData or not saveData.Settings then return end

	local musicEnabled = saveData.Settings.Music-- and not RunService:IsStudio()
	local soundEnabled = saveData.Settings.Sound

	-- Always ensure a track is playing when not in chase; control audibility via the Music sound group volume
	if not isChaseActive then
		if not musicSound.Playing then
			setRandomTrack()
			musicSound.Volume = defaultVolume
			musicSound:Play()
		end
	end

	local musicGroup = SoundService:WaitForChild("Music")
	if musicEnabled then
		musicGroup.Volume = 1
	else
		musicGroup.Volume = 0
	end

	local soundGroup = SoundService:WaitForChild("Main")
	if soundEnabled then
		soundGroup.Volume = 1
	else
		soundGroup.Volume = 0
	end
end

local function PlayChaseMusic(active: boolean)
    if active then
        if isChaseActive then return end
        isChaseActive = true
        -- Pause the normal background track
        if musicSound.Playing then
            pcall(function() musicSound:Pause() end)
        end
        -- Create and play chase music using the Music sound group
        if not chaseSound then
            local newChase = Instance.new("Sound")
            newChase.Name = "ChaseMusic"
            newChase.Looped = true
            newChase.Volume = defaultVolume
            newChase.SoundGroup = SoundService:WaitForChild("Music")
            newChase.Parent = SoundService
            chaseSound = newChase
        end
        if #CHASE_MUSIC_IDS > 0 then
            local idx = math.random(1, #CHASE_MUSIC_IDS)
            local pick = CHASE_MUSIC_IDS[idx]
            local s = chaseSound :: Sound
            s.Looped = true
            s.SoundId = pick
            s:Play()
        else
            warn("CHASE_MUSIC_ID is empty; cannot play chase music")
        end
    else
        if not isChaseActive then return end
        isChaseActive = false
        -- Stop chase music fully
        if chaseSound and (chaseSound :: Sound).Playing then
            local s = chaseSound :: Sound
            pcall(function() s:Stop() end)
        end
        -- Resume normal background track if music is enabled
        updateMusicState()
    end
end

local function init()
	Save.SaveAdded:Connect(updateMusicState)
	Save.Fired(function(key: string, value: any)
		if key == "Settings" then
			updateMusicState()
		end
	end)

	musicSound.Ended:Connect(function()
		-- If the sound is set to loop, Roblox will restart it automatically; we only change when stopped
		if musicSound.Looped then return end
		setRandomTrack()
		musicSound:Play()
	end)

	if Save.Get() then
		updateMusicState()
	end

	-- Chase music toggle based on player carrying attribute, checked each render step
	local lp = game.Players.LocalPlayer
	_RunService.RenderStepped:Connect(function()
		if not lp or not lp.Parent then return end
		local carrying = lp:GetAttribute("CarryingFishId")
		if carrying ~= nil then
			if not isChaseActive then
				PlayChaseMusic(true)
			end
		else
			if isChaseActive then
				PlayChaseMusic(false)
			end
		end
	end)
end

Signal.Fired("ClientLoaded"):Connect(init) 

-- Optional: allow other scripts to toggle via Signal
Signal.Fired("PlayChaseMusic"):Connect(function(active: boolean)
    PlayChaseMusic(active)
end)