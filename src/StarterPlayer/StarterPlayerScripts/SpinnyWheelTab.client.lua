--!strict

local TweenService = game:GetService("TweenService")

local GUI = require(game.ReplicatedStorage.Game.Library.Client.GUI)
local Signal = require(game.ReplicatedStorage.Library.Signal)

-- Position constants
local NORMAL_POSITION = UDim2.new(0.499, 0, 0.323, 0)
local HOVER_POSITION = UDim2.new(0.499, 0, 0.37, 0)
local PRESSED_POSITION = UDim2.new(0.499, 0, 0.4, 0)

-- Tween info
local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- State tracking
local wheelHolder: Frame = nil :: any
local wheelButton: GuiButton = nil :: any
local isHovering = false
local isPressed = false
local rotationTween: Tween? = nil

--[[
    Gets the SpinnyWheel GUI and components
]]
local function getComponents(): (Frame?, GuiButton?)
    local mainGui = GUI.Main()
    if not mainGui then return nil, nil end
    
    local spinnyWheelFrame = mainGui:FindFirstChild("SpinnyWheel")
    if not spinnyWheelFrame or not spinnyWheelFrame:IsA("Frame") then return nil, nil end
    
    local wheelHolderFrame = spinnyWheelFrame:FindFirstChild("WheelHolder")
    if not wheelHolderFrame or not wheelHolderFrame:IsA("Frame") then return nil, nil end
    
    local wheelBtn = wheelHolderFrame:FindFirstChild("Wheel")
    if not wheelBtn or not wheelBtn:IsA("GuiButton") then return nil, nil end
    
    return wheelHolderFrame, wheelBtn
end

--[[
    Tweens the WheelHolder to the specified position
]]
local function tweenToPosition(targetPosition: UDim2)
    if not wheelHolder then return end
    
    local tween = TweenService:Create(wheelHolder, TWEEN_INFO, {
        Position = targetPosition
    })
    
    tween:Play()
end

--[[
    Starts the continuous rotation animation for the Wheel button
]]
local function startWheelRotation()
    if not wheelButton then return end
    
    -- Stop any existing rotation tween
    if rotationTween then
        rotationTween:Cancel()
    end
    
    -- Create rotation tween info (10 seconds for 1 full cycle, linear easing, repeating infinitely)
    local rotationTweenInfo = TweenInfo.new(
        10, -- Duration: 10 seconds
        Enum.EasingStyle.Linear, -- Linear for constant rotation speed
        Enum.EasingDirection.InOut,
        -1, -- Repeat count: -1 means infinite
        false -- Don't reverse
    )
    
    -- Create and start the rotation tween
    rotationTween = TweenService:Create(wheelButton, rotationTweenInfo, {
        Rotation = 360 -- Rotate 360 degrees
    })
    
    if rotationTween then
        rotationTween:Play()
    end
end

--[[
    Handles mouse enter (hover start)
]]
local function onMouseEnter()
    if isPressed then return end -- Don't hover if pressed
    
    isHovering = true
    tweenToPosition(HOVER_POSITION)
end

--[[
    Handles mouse leave (hover end)
]]
local function onMouseLeave()
    if isPressed then return end -- Don't unhover if pressed
    
    isHovering = false
    tweenToPosition(NORMAL_POSITION)
end

--[[
    Handles button press (mouse down)
]]
local function onInputBegan(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isPressed = true
        tweenToPosition(PRESSED_POSITION)
    end
end

--[[
    Handles button release (mouse up)
]]
local function onInputEnded(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isPressed = false
        
        -- Return to appropriate position based on hover state
        if isHovering then
            tweenToPosition(HOVER_POSITION)
        else
            tweenToPosition(NORMAL_POSITION)
        end
    end
end

--[[
    Handles button activation (click)
]]
local function onActivated()
    -- Fire signal to tell SpinnyWheelController to open the "Haunted" wheel
    Signal.Fire("OpenSpinnyWheel", "Haunted")
end

--[[
    Sets up the button interactions
]]
local function setup()
    local holder, button = getComponents()
    if not holder or not button then
        warn("[SpinnyWheelTab] Could not find SpinnyWheel components")
        return
    end
    
    wheelHolder = holder
    wheelButton = button
    
    -- Set initial position
    wheelHolder.Position = NORMAL_POSITION
    
    -- Connect hover events
    wheelButton.MouseEnter:Connect(onMouseEnter)
    wheelButton.MouseLeave:Connect(onMouseLeave)
    
    -- Connect press/release events
    wheelButton.InputBegan:Connect(onInputBegan)
    wheelButton.InputEnded:Connect(onInputEnded)
    
    -- Connect activation event
    wheelButton.Activated:Connect(onActivated)
    
    -- Start the wheel rotation animation
    startWheelRotation()
end

-- Initialize when the script runs
setup()
