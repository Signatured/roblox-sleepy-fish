--!strict

--[[
	Manages the Settings GUI, including button states and player preferences.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local Save = require(ReplicatedStorage.Library.Client.Save)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local DefaultStats = require(ReplicatedStorage.Game.Modules.DefaultStats)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Functions = require(ReplicatedStorage.Library.Functions)

local lastClick = 0
local DEBOUNCE_TIME = 0.2

local settingsGui = GUI.Settings()
local frame = settingsGui:WaitForChild("Frame")
local scrollingFrame = frame:WaitForChild("ScrollHolder"):WaitForChild("ScrollingFrame")
local soundButton = scrollingFrame:WaitForChild("Sound"):WaitForChild("Button")
local musicButton = scrollingFrame:WaitForChild("Music"):WaitForChild("Button")

local onImage = "rbxassetid://127635859252888"
local offImage = "rbxassetid://95787790482910"

local function updateButton(button: ImageButton, isEnabled: boolean)
	local textLabel = button:FindFirstChild("TextLabel")

	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = if isEnabled then "On" else "Off"
	end
	
    button.Image = isEnabled and onImage or offImage
end

local function updateUI(saveData: DefaultStats.schema)
	local playerSettings = saveData.Settings
	if playerSettings then
		updateButton(soundButton, playerSettings.Sound)
		updateButton(musicButton, playerSettings.Music)
	end

	task.delay(0.1, function()	
		Functions.UpdateCanvasSize(scrollingFrame)
	end)
end

local function onSettingsChanged()
    local saveData = Save.Get()
    if not saveData then return end
    updateUI(saveData)
end

function toggleSetting(settingName: string)
	if workspace:GetServerTimeNow() - lastClick < DEBOUNCE_TIME then return end
	lastClick = workspace:GetServerTimeNow()

    local saveData = Save.Get()
    if not saveData then return end

	local newValue = not saveData.Settings[settingName]
    saveData.Settings[settingName] = newValue
    onSettingsChanged()
	
	Network.Fire("SettingChanged", settingName, newValue)
end

ButtonFX(soundButton)
soundButton.Activated:Connect(function()
    toggleSetting("Sound")
end)

ButtonFX(musicButton)
musicButton.Activated:Connect(function()
    toggleSetting("Music")
end)

TabController.Opened:Connect(function(tabId)
    if tabId == "Settings" then
        onSettingsChanged()
    end
end)

Save.SaveAdded:Connect(onSettingsChanged)
Save.Fired(function(key)
    if key == "Settings" then
        onSettingsChanged()
    end
end)