--!strict

--[[
	Manages the background music, respecting the player's in-game settings.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Save = require(ReplicatedStorage.Library.Client.Save)
local Signal = require(ReplicatedStorage.Library.Signal)

local MUSIC_IDS = {
    "rbxassetid://1841647093",
    "rbxassetid://1848354536",
}
local lastIndex: number? = nil

local musicSound = Instance.new("Sound")
musicSound.Name = "BackgroundMusic"
musicSound.Looped = true
musicSound.Volume = 0.25 -- Default volume
musicSound.Parent = SoundService

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

	local musicEnabled = saveData.Settings.Music and not RunService:IsStudio()
	local soundEnabled = saveData.Settings.Sound

	if musicEnabled and not musicSound.Playing then
		setRandomTrack()
		musicSound.Volume = 0.25
		musicSound:Play()
	elseif not musicEnabled and musicSound.Playing then
		musicSound:Stop()
	end

	local soundGroup = SoundService:WaitForChild("Main")
	if soundEnabled then
		soundGroup.Volume = 1
	else
		soundGroup.Volume = 0
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
end

Signal.Fired("ClientLoaded"):Connect(init) 