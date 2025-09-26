--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)
local GUI = require(game.ReplicatedStorage.Game.Library.Client.GUI)
local Functions = require(Library.Functions)

local _LOCAL_PLAYER = Players.LocalPlayer

-- Queue to process messages sequentially
local queue: {{userId: number, text: string}} = {}
local isShowing = false

local function tween(instance: Instance, timeSec: number, goalProps: {[string]: any})
	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(timeSec, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenObj = TweenService:Create(instance, info, goalProps)
	tweenObj:Play()
	return tweenObj
end

local function showNext()
	if isShowing then return end
	local nextItem = table.remove(queue, 1)
	if not nextItem then return end
	isShowing = true

	local gui = GUI.GlobalMessage()
	local frame = gui:WaitForChild("Frame") :: Frame
	local messageLabel = frame:WaitForChild("Message") :: TextLabel
	local adminImage = frame:WaitForChild("AdminImage") :: ImageLabel
	local stroke = messageLabel:FindFirstChildOfClass("UIStroke") :: UIStroke?

	-- Reset visuals
	messageLabel.TextTransparency = 1
	adminImage.ImageTransparency = 1
	if stroke then
		stroke.Transparency = 0
	end
	messageLabel.Text = nextItem.text
	adminImage.Image = ""
	gui.Enabled = true

	-- Load avatar image asynchronously
	task.spawn(function()
		local avatar = Functions.GetAvatarFromUserIdAsync(nextItem.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		if avatar and adminImage and adminImage.Parent then
			adminImage.Image = avatar
		end
	end)

	-- Fade in quickly
	local fadeIn1 = tween(messageLabel, 0.2, {TextTransparency = 0})
	local _fadeIn2 = tween(adminImage, 0.2, {ImageTransparency = 0})
	fadeIn1.Completed:Wait()

	-- Display duration
	task.wait(10)

	-- Fade out over 0.5s
	local fadeOut1 = tween(messageLabel, 0.5, {TextTransparency = 1})
	local _fadeOut2 = tween(adminImage, 0.5, {ImageTransparency = 1})
	if stroke then
		local _fadeOut3 = tween(stroke, 0.5, {Transparency = 1})
	end
	fadeOut1.Completed:Wait()

	-- Extra 0.5s spacing before next message
	task.wait(0.5)

	isShowing = false
	showNext()
end

Network.Fired("Admin Global Message", function(userId: number, text: string)
	queue[#queue+1] = {userId = userId, text = text}
	showNext()
end)


