--!strict

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Audio = require(ReplicatedStorage.Library.Audio)
local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)

-- Track current tween and coroutine to support interruption
local currentTween: Tween? = nil
local currentCoroutine: thread? = nil

local function playJumpscare()
	-- Get the JumpScare GUI
	local jumpscareGui = GUI.JumpScare()
	if not jumpscareGui then
		warn("JumpScare GUI not found!")
		return
	end
	
	local imageLabel = jumpscareGui:FindFirstChildOfClass("ImageLabel")
	if not imageLabel then
		warn("ImageLabel not found in JumpScare GUI!")
		return
	end
	
	-- Stop any existing tween and coroutine
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
	if currentCoroutine then
		task.cancel(currentCoroutine)
		currentCoroutine = nil
	end
	
	-- Play the jumpscare sound
	Audio.Play("rbxassetid://6308606116", script, 1, 1)
	
	-- Enable the GUI and set image to full opacity
	jumpscareGui.Enabled = true
	imageLabel.ImageTransparency = 0
	
	-- Store the current coroutine for potential cancellation
	currentCoroutine = coroutine.running()
	
	-- Wait for 2 seconds, then fade out over 1 second
	task.wait(2)
	
	-- Check if we were cancelled during the wait
	if currentCoroutine ~= coroutine.running() then
		return -- This coroutine was cancelled, don't continue
	end
	
	-- Create fade out tween
	local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	currentTween = TweenService:Create(imageLabel, fadeInfo, {ImageTransparency = 1})
	
	-- When tween completes, disable the GUI
	if currentTween then
		currentTween.Completed:Connect(function()
			jumpscareGui.Enabled = false
			currentTween = nil
			currentCoroutine = nil
		end)
		
		currentTween:Play()
	end
end

-- Listen for jumpscare events from the server
Network.Fired("AdminPanel_Jumpscare", function()
	-- Spawn in a separate thread to avoid blocking
	task.spawn(playJumpscare)
end)
