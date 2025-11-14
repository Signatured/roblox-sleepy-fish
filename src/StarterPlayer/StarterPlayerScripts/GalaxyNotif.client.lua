--!strict

-- Displays a Galaxy notification image under Main GUI when the Galaxy event is active.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules (absolute game.* paths, top-of-file)
local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local MutationEventCmds = require(ReplicatedStorage.Game.Library.Client.MutationEventCmds)

-- Configuration
local FLASH_DURATION_SECONDS = 6
local HIDE_DELAY_SECONDS = 6
local TWEEN_TIME = 0.3
local MIN_TRANSPARENCY = 0 -- solid
local MAX_TRANSPARENCY = 0.5 -- half transparent

-- State
local stateToken = 0 -- increments each time the event state changes; used to cancel running effects
local currentTween: Tween? = nil

-- Get GUI references
local mainGui = GUI.Main()
local notif = mainGui:WaitForChild("GalaxyNotif") :: ImageLabel

-- Helper to cancel any active tweens on the notif
local function cancelTweens()
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
end

local function setVisible(isVisible: boolean)
	notif.Visible = isVisible
end

local function setTransparency(value: number)
	notif.ImageTransparency = value
end

local function flashThenSolidify(currentToken: number)
	-- Make sure visible and start flashing between MIN and MAX transparency
	setVisible(true)
	local elapsed = 0
	local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local toMax = true
	while elapsed < FLASH_DURATION_SECONDS do
		if currentToken ~= stateToken then return end
		local target = toMax and MAX_TRANSPARENCY or MIN_TRANSPARENCY
		local tween: Tween = TweenService:Create(notif, tweenInfo, { ImageTransparency = target })
		currentTween = tween
		tween:Play()
		tween.Completed:Wait()
		currentTween = nil
		elapsed = elapsed + TWEEN_TIME
		toMax = not toMax
	end
	if currentToken ~= stateToken then return end
	-- Solidify
	cancelTweens()
	setTransparency(MIN_TRANSPARENCY)
end

local function handleEventStarted()
	stateToken = stateToken + 1
	local token = stateToken
	-- Ensure visible and start flashing for 6s, then solidify
	setVisible(true)
	setTransparency(MIN_TRANSPARENCY)
	task.spawn(function()
		flashThenSolidify(token)
	end)
end

local function handleEventEnded()
	stateToken = stateToken + 1
	local token = stateToken
	-- Wait 6s then hide, unless event reactivates
	task.delay(HIDE_DELAY_SECONDS, function()
		if token ~= stateToken then return end
		setVisible(false)
		cancelTweens()
		setTransparency(MIN_TRANSPARENCY)
	end)
end

-- Initialize according to current status
do
	local isActive = MutationEventCmds.IsYinYangActive()
	if isActive then
		setVisible(true)
		setTransparency(MIN_TRANSPARENCY)
		handleEventStarted()
	else
		setVisible(false)
		setTransparency(MIN_TRANSPARENCY)
	end
end

-- Poll for changes every second
task.spawn(function()
	local wasActive = MutationEventCmds.IsYinYangActive()
	while true do
		task.wait(1)
		local isActive = MutationEventCmds.IsYinYangActive()
		if isActive ~= wasActive then
			if isActive then
				handleEventStarted()
			else
				handleEventEnded()
			end
			wasActive = isActive
		end
	end
end)


