--!strict

local Players = game:GetService("Players")

local GUI = require(game.ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(game.ReplicatedStorage.Library.Client.TabController)
local AdminPanelCmds = require(game.ReplicatedStorage.Game.Library.Client.AdminPanelCmds)
local AdminPanelDirectory = require(game.ReplicatedStorage.Game.Library.Directory.AdminPanel)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local ButtonFX = require(game.ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local GetAvatarFromUserIdAsync = require(game.ReplicatedStorage.Library.Functions.GetAvatarFromUserIdAsync)

local LocalPlayer = Players.LocalPlayer

-- State tracking
local currentTargetPlayer: Player? = nil
local playerButtons: {[Player]: ImageButton} = {}
local commandButtons: {[string]: {button: GuiButton, lockedFrame: Frame, textLabel: TextLabel}} = {}
local adminPanelGui: ScreenGui? = nil
local initialized = false
local globalModeEnabled = false
local globalButton: ImageButton? = nil
local globalBtnConnection: RBXScriptConnection? = nil
local textBoxConnection: RBXScriptConnection? = nil

-- Persistent cooldown tracking (survives GUI reopening)
local cooldownTimers: {[string]: {endTime: number, connection: RBXScriptConnection?}} = {}

-- Privileged ranks that can use global commands
local PRIVILEGED_RANKS = {
    ["Developer"] = true,
    ["Owner"] = true,
    ["Admin"] = true,
}

--[[
    Checks if the local player has privileged permissions for global commands
]]
local function hasPrivilegedPermission(): boolean
    local rank = LocalPlayer:GetAttribute("Rank")
    return rank and PRIVILEGED_RANKS[rank] or false
end

--[[
    Gets the AdminPanel GUI
]]
local function getGui(): ScreenGui?
    if not adminPanelGui then
        adminPanelGui = GUI.AdminPanel()
    end
    return adminPanelGui
end

--[[
    Updates the global button appearance
]]
local function updateGlobalButton()
    if not globalButton then return end
    
    if globalModeEnabled then
        globalButton.Image = "rbxassetid://77069495828979" -- Check mark
    else
        globalButton.Image = "rbxassetid://74498973059780" -- X mark
    end
end

--[[
    Toggles global mode on/off
]]
local function toggleGlobalMode()
    globalModeEnabled = not globalModeEnabled
    updateGlobalButton()
end

--[[
    Updates the cooldown display for a command
]]
local function updateCooldownDisplay(commandName: string)
    local commandData = commandButtons[commandName]
    if not commandData then return end
    
    local cooldownData = cooldownTimers[commandName]
    if not cooldownData then
        -- No cooldown, hide locked frame
        commandData.lockedFrame.Visible = false
        return
    end
    
    local currentTime = workspace:GetServerTimeNow()
    local remainingTime = cooldownData.endTime - currentTime
    
    if remainingTime <= 0 then
        -- Cooldown finished
        commandData.lockedFrame.Visible = false
        if cooldownData.connection then
            cooldownData.connection:Disconnect()
        end
        cooldownTimers[commandName] = nil
    else
        -- Show cooldown
        commandData.lockedFrame.Visible = true
        commandData.textLabel.Text = math.ceil(remainingTime) .. "s"
    end
end

--[[
    Starts a cooldown timer for a command
]]
local function startCooldown(commandName: string, duration: number)
    local commandData = commandButtons[commandName]
    if not commandData then return end
    
    -- Clear existing cooldown
    local existingCooldown = cooldownTimers[commandName]
    if existingCooldown and existingCooldown.connection then
        existingCooldown.connection:Disconnect()
    end
    
    local endTime = workspace:GetServerTimeNow() + duration
    
    -- Create heartbeat connection to update display
    local connection = game:GetService("RunService").Heartbeat:Connect(function()
        updateCooldownDisplay(commandName)
    end)
    
    cooldownTimers[commandName] = {
        endTime = endTime,
        connection = connection
    }
    
    -- Initial update
    updateCooldownDisplay(commandName)
end

--[[
    Creates a command button from the template
]]
local function createCommandButton(commandName: string, commandData, parent: Instance, template: GuiButton): GuiButton
    local button = template:Clone()
    button.Name = commandName
    button.Visible = true
    
	-- Find child container (supports new layout where Title/Icon are under Content)
	local contentContainer = button:FindFirstChild("Content")
	local titleParent: Instance = contentContainer or button
	local iconParent: Instance = contentContainer or button

	-- Set the display name
	local title = titleParent:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = string.lower(";" .. commandData.DisplayName)
	end

	-- Set the icon image if present on template and command data
	local icon = iconParent:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		local iconId = (commandData and commandData.Icon)
		if typeof(iconId) == "string" and #iconId > 0 then
			icon.Image = iconId
		end
	end
    
    -- Get the locked frame and its text label
    local lockedFrame = button:FindFirstChild("Locked")::Frame
    local textLabel = lockedFrame and lockedFrame:FindFirstChild("TextLabel")
    
    if lockedFrame and textLabel then
        lockedFrame.Visible = false -- Initially hidden
        commandButtons[commandName] = {
            button = button,
            lockedFrame = lockedFrame :: Frame,
            textLabel = textLabel :: TextLabel
        }
    end
    
    -- Add ButtonFX
    ButtonFX(button)
    
    -- Connect the click event
    button.Activated:Connect(function()
        -- Check if command is on cooldown
        if cooldownTimers[commandName] then
            return -- Command is on cooldown, ignore click
        end
        
        local targetPlayer = currentTargetPlayer or LocalPlayer
        
        -- Execute command with global flag if global mode is enabled and command allows it
        local commandConfig = AdminPanelDirectory[commandName]
        local preventGlobal = commandConfig and commandConfig.PreventGlobal
        if globalModeEnabled and hasPrivilegedPermission() and not preventGlobal then
            AdminPanelCmds.ExecuteCommand(commandName, targetPlayer, true) -- true for global
        else
            AdminPanelCmds.ExecuteCommand(commandName, targetPlayer)
        end
        
        -- Start cooldown (privileged roles get reduced cooldown)
        if commandData.Cooldown and commandData.Cooldown > 0 then
            local cooldownDuration = hasPrivilegedPermission() and 1 or commandData.Cooldown
            startCooldown(commandName, cooldownDuration)
        end
    end)
    
    button.Parent = parent
    return button
end

--[[
    Creates a player button from the template
]]
local function createPlayerButton(player: Player, parent: Instance, template: ImageButton): ImageButton
    local button = template:Clone()::ImageButton
    button.Name = player.Name
    button.Visible = true
    button.Image = "rbxassetid://75836186235217" -- Default unselected image
    
    -- Set the name
    local title = button:FindFirstChild("Title")
    if title and title:IsA("TextLabel") then
        title.Text = player.Name
    end
    
    -- Set up the player face
    local playerFace = button:FindFirstChild("PlayerFace")
    if playerFace and playerFace:IsA("ImageLabel") then
        -- Set to blank initially
        playerFace.Image = ""
        
        -- Load avatar asynchronously
        task.spawn(function()
            local avatarUrl = GetAvatarFromUserIdAsync(
                player.UserId, 
                Enum.ThumbnailType.HeadShot, 
                Enum.ThumbnailSize.Size150x150
            )
            if avatarUrl then
                playerFace.Image = avatarUrl
            end
        end)
    end
    
    -- Add ButtonFX
    ButtonFX(button)
    
    -- Connect the click event
    button.Activated:Connect(function()
        -- Update target selection
        currentTargetPlayer = player
        
        -- Update visual selection
        for _, btn in pairs(playerButtons) do
            -- Reset all buttons to default state
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Default color
            btn.Image = "rbxassetid://75836186235217" -- Unselected image
        end
        
        -- Highlight selected button
        button.BackgroundColor3 = Color3.fromRGB(0, 162, 255) -- Selection color
        button.Image = "rbxassetid://123813453691289" -- Selected image
    end)
    
    button.Parent = parent
    return button
end

--[[
    Sorts players with LocalPlayer first, then alphabetically by DisplayName
]]
local function sortPlayers(playerList: {Player}): {Player}
    table.sort(playerList, function(a: Player, b: Player)
        -- LocalPlayer always comes first
        if a == LocalPlayer then
            return true
        elseif b == LocalPlayer then
            return false
        else
            -- Sort others alphabetically by DisplayName
            return a.DisplayName < b.DisplayName
        end
    end)
    return playerList
end

--[[
    Updates the player list
]]
local function updatePlayerList()
    local gui = getGui()
    if not gui then return end
    
    local frame = gui:FindFirstChild("Frame")
    if not frame then return end
    
    local playersFrame = frame:FindFirstChild("Players")
    if not playersFrame then return end
    
    local scrollingFrame = playersFrame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return end
    
    local template = scrollingFrame:FindFirstChild("PlayerButton")
    if not template or not template:IsA("ImageButton") then return end
    
    -- Hide template
    template.Visible = false
    
    -- Clear existing buttons
    for player, button in pairs(playerButtons) do
        if button and button.Parent then
            button:Destroy()
        end
    end
    playerButtons = {}
    
    -- Get all players and sort them
    local allPlayers = Players:GetPlayers()
    allPlayers = sortPlayers(allPlayers)
    
    -- Create buttons for each player
    for i, player in ipairs(allPlayers) do
        local button = createPlayerButton(player, scrollingFrame, template)
        button.LayoutOrder = i
        
        playerButtons[player] = button
    end
    
		-- Restore previously selected target if still online; otherwise select LocalPlayer
		if currentTargetPlayer and playerButtons[currentTargetPlayer] then
			playerButtons[currentTargetPlayer].BackgroundColor3 = Color3.fromRGB(0, 162, 255)
			playerButtons[currentTargetPlayer].Image = "rbxassetid://123813453691289" -- Selected image
		else
			currentTargetPlayer = LocalPlayer
			if playerButtons[LocalPlayer] then
				playerButtons[LocalPlayer].BackgroundColor3 = Color3.fromRGB(0, 162, 255)
				playerButtons[LocalPlayer].Image = "rbxassetid://123813453691289" -- Selected image
			end
		end
end

--[[
    Sets up the command buttons
]]
local function setupCommands()
    local gui = getGui()
    if not gui then return end
    
    local frame = gui:FindFirstChild("Frame")
    if not frame then return end
    
    local commandsFrame = frame:FindFirstChild("Commands")
    if not commandsFrame then return end
    
    local contentFrame = commandsFrame:FindFirstChild("Content")
    if not contentFrame then return end
    
    local template = contentFrame:FindFirstChild("CommandButton")
    if not template or not template:IsA("GuiButton") then return end
    
    -- Hide template
    template.Visible = false
    
    -- Clear existing buttons
    for commandName, commandData in pairs(commandButtons) do
        if commandData.button and commandData.button.Parent then
            commandData.button:Destroy()
        end
    end
    commandButtons = {}
    
    -- Create buttons for each command
    for commandName, commandData in pairs(AdminPanelDirectory) do
        createCommandButton(commandName, commandData, contentFrame, template)
    end
    
    -- Restore cooldown displays for any active cooldowns
    for commandName, cooldownData in pairs(cooldownTimers) do
        if cooldownData.endTime > workspace:GetServerTimeNow() then
            -- Cooldown is still active, restore the display
            updateCooldownDisplay(commandName)
        else
            -- Cooldown has expired while GUI was closed, clean it up
            if cooldownData.connection then
                cooldownData.connection:Disconnect()
            end
            cooldownTimers[commandName] = nil
        end
    end
end

--[[
    Handles when a player joins
]]
local function onPlayerAdded(player: Player)
    if initialized then
        updatePlayerList()
    end
end

--[[
    Handles when a player leaves
]]
local function onPlayerRemoving(player: Player)
    -- If the leaving player was selected, select LocalPlayer
    if currentTargetPlayer == player then
        currentTargetPlayer = LocalPlayer
        -- Update visual selection if GUI is open
        if initialized and playerButtons[LocalPlayer] then
            -- Reset all buttons to unselected state
            for _, btn in pairs(playerButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                btn.Image = "rbxassetid://75836186235217"
            end
            -- Select LocalPlayer
            playerButtons[LocalPlayer].BackgroundColor3 = Color3.fromRGB(0, 162, 255)
            playerButtons[LocalPlayer].Image = "rbxassetid://123813453691289"
        end
    end
    
    -- Clean up the button
    if playerButtons[player] then
        playerButtons[player]:Destroy()
        playerButtons[player] = nil
    end
    
    if initialized then
        updatePlayerList()
    end
end

--[[
    Sets up the GlobalThings frame and Global button
]]
local function setupGlobalThings()
    local gui = getGui()
    if not gui then return end
    
    local frame = gui:FindFirstChild("Frame")
    if not frame then return end
    
    local globalThingsFrame = frame:FindFirstChild("GlobalThings")::GuiButton
    if not globalThingsFrame then return end
    
    -- Only show GlobalThings frame for privileged users
    globalThingsFrame.Visible = hasPrivilegedPermission()
    
    if not hasPrivilegedPermission() then return end
    
    -- Set up the Global button
    local globalBtn = globalThingsFrame:FindFirstChild("Global")
    if globalBtn and globalBtn:IsA("ImageButton") then
        globalButton = globalBtn

		-- Reflect current persisted state
		updateGlobalButton()

		-- Add ButtonFX once
		if not globalBtn:GetAttribute("FxApplied") then
			ButtonFX(globalBtn)
			globalBtn:SetAttribute("FxApplied", true)
		end

		-- Ensure we don't stack multiple connections across reopens
		if globalBtnConnection then
			globalBtnConnection:Disconnect()
			globalBtnConnection = nil
		end
		globalBtnConnection = globalBtn.Activated:Connect(toggleGlobalMode)
    end
end

--[[
    Sets up the TextBox command input under AdminPanel/Frame
]]
local function setupTextBox()
    local gui = getGui()
    if not gui then return end

    print("test1")

    local frame = gui:FindFirstChild("Frame")
    if not frame then return end

    print("test2")

    local tbl = frame:FindFirstChild("TextBox")
    if not tbl or not tbl:IsA("ImageLabel") then return end

    local tb = tbl:FindFirstChild("TextBox")
    if not tb or not tb:IsA("TextBox") then return end

    if textBoxConnection then
        textBoxConnection:Disconnect()
        textBoxConnection = nil
    end

    textBoxConnection = tb.FocusLost:Connect(function(enterPressed: boolean)
        if not enterPressed then return end

        local raw = tb.Text or ""
        if string.match(raw, "^%s*$") then return end

        -- Clear immediately on submit
        tb.Text = ""

        -- Parse first two tokens (command and target)
        local cmdToken, targetToken = string.match(raw, "^%s*(%S+)%s*(%S*)")
        if not cmdToken or cmdToken == "" then return end

        -- Strip optional leading ';'
        if string.sub(cmdToken, 1, 1) == ";" then
            cmdToken = string.sub(cmdToken, 2)
        end
        local cmdLower = string.lower(cmdToken)

        -- Resolve to canonical command name from AdminPanelDirectory
        local resolvedName: string? = nil
        local resolvedConfig: any = nil
        for key, cfg in pairs(AdminPanelDirectory) do
            if string.lower(key) == cmdLower or (cfg and cfg.DisplayName and string.lower(cfg.DisplayName) == cmdLower) then
                resolvedName = key
                resolvedConfig = cfg
                break
            end
        end
        if not resolvedName then
            NotificationCmds.Message("That's not a valid command!", { Color = Color3.fromRGB(255, 0, 0) })
            return
        end

        -- Check client-side cooldown for this command
        local cooldownData = cooldownTimers[resolvedName]
        if cooldownData then
            local remaining = cooldownData.endTime - workspace:GetServerTimeNow()
            if remaining > 0 then
                NotificationCmds.Message("That command is on cooldown for " .. tostring(math.ceil(remaining)) .. " seconds!", { Color = Color3.fromRGB(255, 0, 0) })
                return
            end
        end

        -- Determine target player (defaults to LocalPlayer when omitted)
        local targetPlayer: Player? = nil
        if not targetToken or targetToken == "" then
            targetPlayer = LocalPlayer
        else
            -- Find an online player by exact (case-insensitive) or prefix match on Name/DisplayName
            local function findPlayerByQuery(query: string): Player?
                local q = string.lower(query)
                -- exact
                for _, p in ipairs(Players:GetPlayers()) do
                    if string.lower(p.Name) == q or string.lower(p.DisplayName) == q then
                        return p
                    end
                end
                -- prefix
                for _, p in ipairs(Players:GetPlayers()) do
                    if string.sub(string.lower(p.Name), 1, #q) == q or string.sub(string.lower(p.DisplayName), 1, #q) == q then
                        return p
                    end
                end
                return nil
            end

            targetPlayer = findPlayerByQuery(targetToken)
            if not targetPlayer then
                NotificationCmds.Message(targetToken .. " isn't online!", { Color = Color3.fromRGB(255, 0, 0) })
                return
            end
        end

        -- Execute the command (non-global from textbox)
        AdminPanelCmds.ExecuteCommand(resolvedName :: string, targetPlayer)

        -- Start cooldown visualization if applicable
        if resolvedConfig and resolvedConfig.Cooldown and resolvedConfig.Cooldown > 0 then
            local duration = hasPrivilegedPermission() and 1 or resolvedConfig.Cooldown
            startCooldown(resolvedName :: string, duration)
        end
    end)
end

--[[
    Initializes the AdminPanel GUI
]]
local function setup()
    if initialized then return end
    
    local gui = getGui()
    if not gui then return end
    
    -- Set up global things
    setupGlobalThings()
    
    -- Set up commands
    setupCommands()
    
    -- Set up player list
    updatePlayerList()
    
    -- Set up TextBox submit handling
    setupTextBox()
    
    initialized = true
end

--[[
    Cleans up when the AdminPanel is closed
]]
local function cleanup()
		-- Keep target selection to restore on next open (only reset visuals/state)
		
	-- Disconnect global button connection but keep state to persist across reopens
	if globalBtnConnection then
		globalBtnConnection:Disconnect()
		globalBtnConnection = nil
	end
	globalButton = nil
    
    -- Clear player buttons
    for player, button in pairs(playerButtons) do
        if button and button.Parent then
            button:Destroy()
        end
    end
    playerButtons = {}
    
    -- Clear command buttons (but keep cooldown timers running)
    for commandName, commandData in pairs(commandButtons) do
        if commandData.button and commandData.button.Parent then
            commandData.button:Destroy()
        end
    end
    commandButtons = {}
    
    -- Disconnect textbox handler
    if textBoxConnection then
        textBoxConnection:Disconnect()
        textBoxConnection = nil
    end
    
    -- Note: We don't clear cooldownTimers here so they persist across GUI reopening
    
    initialized = false
end

-- Connect player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Connect to existing players
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Connect to TabController events
TabController.Opened:Connect(function(tabId: string)
    if tabId == "AdminPanel" then
        setup()
    end
end)

TabController.Closed:Connect(function(tabId: string)
    if tabId == "AdminPanel" then
        cleanup()
    end
end)

-- If AdminPanel is already open, set it up
if TabController.GetCurrentTab() == "AdminPanel" then
    setup()
end