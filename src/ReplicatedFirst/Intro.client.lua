--!strict

--[[
	This script manages the loading screen, breaking the process into several stages
	and providing visual feedback to the player.
]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local STAGES = {
	GAME_LOADED = { Progress = 0.2, Text = "Loading Game" },
	CHARACTER_LOADED = { Progress = 0.4, Text = "Loading Character" },
	MAP_LOADED = { Progress = 0.6, Text = "Loading Map" },
	LIBRARY_LOADED = { Progress = 0.8, Text = "Loading Library" },
	SAVE_LOADED = { Progress = 0.95, Text = "Loading Save" },
    DONE = { Progress = 1, Text = "Loading Done" },
}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local viewportY = workspace.CurrentCamera.ViewportSize.Y
local playerGui
local loadingScreen

local gameGuis = {}
local _SKIP = RunService:IsStudio()

-- Main loading logic
local function main()
    local player = Players.LocalPlayer
    playerGui = player:WaitForChild("PlayerGui")

    -- Get the loading screen GUI and parent it to the PlayerGui
    loadingScreen = ReplicatedFirst:WaitForChild("LoadingScreen")
	loadingScreen.Enabled = true
    loadingScreen.Parent = playerGui

    -- GUI elements
    local Frame = loadingScreen:WaitForChild("Frame")
    local Progress = Frame:WaitForChild("LoadingBar"):WaitForChild("ProgressContainer")
    local Bar = Progress:WaitForChild("ProgressBar")
    local SkipButton = Frame:WaitForChild("SkipButton")
    local LoadingText = Frame:WaitForChild("LoadingBar"):WaitForChild("CurrentLoading")

    -- Function to tween the progress bar
    local function updateProgress(targetProgress: number, text: string, skip: boolean?)
        local tween = TweenService:Create(Bar, TWEEN_INFO, { Size = UDim2.new(targetProgress, 0, 1, 0) })
        tween:Play()

        if not skip then
            tween.Completed:Wait()
        end
    end

    -- Animate the "Loading..." text
    task.spawn(function()
        local dots = 1
        while loadingScreen.Parent do
            LoadingText.Text = "Loading" .. string.rep(".", dots)
            dots = (dots % 3) + 1
            task.wait(0.25)
        end
    end)

    local function toggleCoreUI(enabled: boolean)
        if viewportY < 550 then
            return
        end 

        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled)
    end

    --- Remove default loading screen
	game.ReplicatedFirst:RemoveDefaultLoadingScreen()
    toggleCoreUI(false)
    hideAllGuis()

	-- Stage 1: Wait for game to be loaded
	updateProgress(STAGES.GAME_LOADED.Progress, STAGES.GAME_LOADED.Text)
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	-- Stage 2: Wait for player's character and humanoid
	updateProgress(STAGES.CHARACTER_LOADED.Progress, STAGES.CHARACTER_LOADED.Text)
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	player.Character:WaitForChild("Humanoid")

	-- Stage 3: Wait for map to load (skippable)
	updateProgress(STAGES.MAP_LOADED.Progress, STAGES.MAP_LOADED.Text)
	SkipButton.Visible = true
	local mapLoaded = false
	local skipConnection
	local skipped = false
	
	skipConnection = SkipButton.MouseButton1Click:Connect(function()
		skipped = true
		SkipButton.Visible = false
		if skipConnection then
			skipConnection:Disconnect()
		end
	end)
	
	task.spawn(function()
		Workspace:WaitForChild("Map") -- Assuming ObbyArea is part of the map
		mapLoaded = true
	end)
	
	repeat task.wait() until mapLoaded or skipped
	
	if skipConnection and not skipped then
		skipConnection:Disconnect()
	end
	SkipButton.Visible = false

	-- Stage 4: Wait for client library to be loaded
	updateProgress(STAGES.LIBRARY_LOADED.Progress, STAGES.LIBRARY_LOADED.Text)
	local Library = ReplicatedStorage:WaitForChild("Library")
	local Save = require(Library.Client.Save)

	-- Stage 5: Wait for client save to be loaded
	updateProgress(STAGES.SAVE_LOADED.Progress, STAGES.SAVE_LOADED.Text)
	while not Save.Get() do
		task.wait(0.05)
	end

    local ClientPlot = require(ReplicatedStorage.Plot.ClientPlot)
    while not ClientPlot.GetLocal() do
        task.wait(0.05)
    end

    updateProgress(STAGES.DONE.Progress, STAGES.DONE.Text, true)

	-- Loading complete
	task.wait(0.1)

    player:SetAttribute("LoadingScreenComplete", true)

    toggleCoreUI(true)
    restore()
end

function hideAllGuis()
	local function loop()
		for _, v in ipairs(playerGui:GetChildren()) do
			if v.Name == "Dex" or v.Name == "DebugStats" then
				continue
			end
			if v.ClassName == "ScreenGui" or v.ClassName == "BillboardGui" or v.ClassName == "SurfaceGui" then
				if v.Enabled and v.Name ~= "LoadingScreen" then
					if not table.find(gameGuis, v) then
						table.insert(gameGuis, v)
					end
					v.Enabled = false
				end		
			end
		end
	end

	--- Runs a constant loop looking for game guis and disabling them (while maintaining a cache)
	task.spawn(function()
		while (loadingScreen.Parent) do
			loop()
			task.wait()
		end
	end)
end

function restore()
	game.Debris:AddItem(loadingScreen, 0)

	for _, v in ipairs(gameGuis) do
		v.Enabled = true
	end
end

-- Run the loading sequence in a protected call
local success, err = pcall(function()
    if not _SKIP then
        main()
    end
end)
if not success then
	warn("Loading screen error:", err)
	-- Fallback to destroy the loading screen if it errors
	if loadingScreen then
		loadingScreen:Destroy()
	end
end 