--!strict

--[[
	Manages the background music, respecting the player's in-game settings.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Save/Signal may not be available immediately in ReplicatedFirst
local Save: any = nil
local _Signal: any = nil

local MUSIC_IDS = {
    "rbxassetid://1841647093",
    "rbxassetid://1848354536",
    "rbxassetid://1838457617",
    "rbxassetid://106841913062814"
}
local CHASE_MUSIC_IDS = {
    "rbxassetid://1847683491",
	"rbxassetid://76893650686729",
	"rbxassetid://106684853320177"
}
local lastIndex: number? = nil
local defaultVolume = 0.15

local musicSound = Instance.new("Sound")
musicSound.Name = "BackgroundMusic"
musicSound.Looped = true
musicSound.Volume = defaultVolume -- Default volume
musicSound.Parent = SoundService
musicSound.SoundGroup = SoundService:WaitForChild("Music")

local isChaseActive = false
local chaseSound: Sound? = nil
local chasePreloaded: {[string]: Sound} = {}
local preChaseState = {
    wasPlaying = false,
    soundId = "",
    timePosition = 0,
}

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
	local saveData = (Save and Save.Get and Save.Get())
	if not saveData or not saveData.Settings then return end

	local musicEnabled = saveData.Settings.Music
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
	musicGroup.Volume = musicEnabled and 1 or 0

	local soundGroup = SoundService:WaitForChild("Main")
	soundGroup.Volume = soundEnabled and 1 or 0
end

local function PlayChaseMusic(active: boolean)
    if active then
        if isChaseActive then return end
        isChaseActive = true
        -- Pause the normal background track
        preChaseState.wasPlaying = musicSound.Playing
        preChaseState.soundId = musicSound.SoundId
        preChaseState.timePosition = musicSound.TimePosition
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
        -- Resume the exact track/time from before the chase, if it was playing
        if preChaseState.wasPlaying then
            -- restore id and time in case anything changed while paused
            if preChaseState.soundId ~= "" then
                musicSound.SoundId = preChaseState.soundId
            end
            musicSound.TimePosition = preChaseState.timePosition
            pcall(function()
                if musicSound.IsPaused then
                    musicSound:Resume()
                else
                    musicSound:Play()
                end
            end)
        end
        -- Apply volumes per current settings
        updateMusicState()
    end
end

local function init()
	-- Start playing by default before save/settings are available
	if not musicSound.Playing then
		setRandomTrack()
		musicSound.Volume = defaultVolume
		musicSound:Play()
		local musicGroup = SoundService:WaitForChild("Music")
		musicGroup.Volume = 1
		local soundGroup = SoundService:WaitForChild("Main")
		soundGroup.Volume = 1
	end

	-- When Library replicates, wire Save/Signal and listen for updates
	task.spawn(function()
		local lib = ReplicatedStorage:WaitForChild("Library")
		local okSave, modSave = pcall(function() return require(lib.Client.Save) end)
		if okSave then Save = modSave end
		local okSignal, modSignal = pcall(function() return require(lib.Signal) end)
		if okSignal then _Signal = modSignal end

		if Save then
			if Save.SaveAdded then
				Save.SaveAdded:Connect(updateMusicState)
			end
			if Save.Fired then
				Save.Fired(function(key: string, _value: any)
					if key == "Settings" then
						updateMusicState()
					end
				end)
			end
			if Save.Get() then
				updateMusicState()
			end
		end
	end)

	musicSound.Ended:Connect(function()
		-- If the sound is set to loop, Roblox will restart it automatically; we only change when stopped
		if musicSound.Looped then return end
		setRandomTrack()
		musicSound:Play()
	end)

	-- Chase music toggle based on player carrying attribute, checked each render step
	local lp = game.Players.LocalPlayer
	RunService.RenderStepped:Connect(function()
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

-- Try to use Signal if available; otherwise just run init
local okSigLib, sigLib = pcall(function()
	return ReplicatedStorage.Library and require(ReplicatedStorage.Library.Signal)
end)
if okSigLib and sigLib and sigLib.Fired then
	sigLib.Fired("ClientLoaded"):Connect(init)
else
	init()
end