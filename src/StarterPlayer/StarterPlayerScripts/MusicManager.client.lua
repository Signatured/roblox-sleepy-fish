--!strict

--[[
	Manages the background music, respecting the player's in-game settings.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Save = require(ReplicatedStorage.Library.Client.Save)
local Signal = require(ReplicatedStorage.Library.Signal)

local MUSIC_ID = "rbxassetid://101791676294835" -- Placeholder music ID

local musicSound = Instance.new("Sound")
musicSound.Name = "BackgroundMusic"
musicSound.SoundId = MUSIC_ID
musicSound.Looped = true
musicSound.Volume = 0.25 -- Default volume
musicSound.Parent = SoundService

local function updateMusicState()
	local saveData = Save.Get()
	if not saveData or not saveData.Settings then return end

	local musicEnabled = saveData.Settings.Music and not RunService:IsStudio()
	local soundEnabled = saveData.Settings.Sound

	if musicEnabled and not musicSound.Playing then
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

	if Save.Get() then
		updateMusicState()
	end
end

Signal.Fired("ClientLoaded"):Connect(init) 