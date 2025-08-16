--!strict

local Players = game:GetService("Players")

local Player = require(game.ReplicatedStorage.Library.Player)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local Functions = require(game.ReplicatedStorage.Library.Functions)

local config = {
	JumpPower = 50,
    TravelTime = 1.5
}

local localPlayer = Players.LocalPlayer

local function AnchorLocally()
	local primaryPart = Player.Optional.PrimaryPart()
	if not primaryPart or not primaryPart:FindFirstChild("RootAttachment") then
		return
	end
	
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "LocalAnchorPosition"
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.MaxForce = math.huge
	alignPosition.Responsiveness = 200
	alignPosition.Position = primaryPart.Position
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = primaryPart:FindFirstChild("RootAttachment")::Attachment
	alignPosition.Parent = primaryPart
	
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "LocalAnchorOrientation"
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = 200
	alignOrientation.CFrame = CFrame.Angles(primaryPart.CFrame:ToEulerAnglesXYZ())
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = primaryPart:FindFirstChild("RootAttachment")::Attachment
	alignOrientation.Parent = primaryPart
	
	primaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	
	local humanoid = Player.Humanoid()
	if humanoid then
		humanoid.JumpPower = 0
	end
end

local function UnanchorLocally()
	local primaryPart = Player.Optional.PrimaryPart()
	if not primaryPart then
		return
	end
	
	local alignAttachment = primaryPart:FindFirstChild("LocalAnchorPosition")::AlignPosition
	if alignAttachment then
		alignAttachment:Destroy()
	end

	local alignOrientation = primaryPart:FindFirstChild("LocalAnchorOrientation")::AlignOrientation
	if alignOrientation then
		alignOrientation:Destroy()
	end
	
	local humanoid = Player.Humanoid()
	if humanoid then
		humanoid.JumpPower = config.JumpPower
	end
end

function Death(spawnPos: CFrame)
	AnchorLocally()

    local camera = workspace.CurrentCamera
    local fieldOfView = camera.FieldOfView

    local character = Player.Character()
    local humanoid = Player.Humanoid()
    local primaryPart = Player.PrimaryPart()
    localPlayer:SetAttribute("Flying", true)

    humanoid.PlatformStand = true

    local positionA = Player.Position()
    local positionB = spawnPos.Position

    local midPoint = positionA:Lerp(positionB, 0.5)
    local midPointWithHeight = Vector3.new(midPoint.X, 215, midPoint.Z)

    -- Bezier curve
    local controlPoints = { 
        positionA,
        midPointWithHeight,
        positionB
    }
    local bezier = Functions.Bezier(table.unpack(controlPoints))

    local function GetCFrameFromBez(bez: Vector3, _angle: CFrame?)
        local currentCFrame = character:GetPivot()
        local newPosition = (currentCFrame - currentCFrame.Position) + bez
        local angle = _angle or CFrame.lookAt(currentCFrame.Position, newPosition.Position)
        
        return angle - angle.Position + newPosition.Position
    end

    -- Setup initial position
    local starterCFrame = GetCFrameFromBez(bezier(0.0001))
    character:PivotTo(starterCFrame)
    Functions.RenderStepped(function(dt: number, t: number)
        local alpha = Functions.Easing(t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local bez = bezier(alpha)
        local newCFrame = GetCFrameFromBez(bez, bez == positionB and starterCFrame or nil)
        
        local alignAttachment = primaryPart:FindFirstChild("LocalAnchorPosition")::AlignPosition
        alignAttachment.Position = newCFrame.Position
        
        local alignOrientation = primaryPart:FindFirstChild("LocalAnchorOrientation")::AlignOrientation
        alignOrientation.CFrame = CFrame.Angles(newCFrame:ToEulerAnglesXYZ())
        
        character:PivotTo(newCFrame)
        
        --- fov and camera shake
        local sineAlpha = Functions.Easing(t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        camera.FieldOfView = fieldOfView + (sineAlpha * 30)
    end, config.TravelTime, true, nil, Enum.RenderPriority.Camera.Value - 1):Wait()

    camera.FieldOfView = fieldOfView

    UnanchorLocally()
    localPlayer:SetAttribute("Flying", false)
end

ClientPlot.OnLocalAndCreated(function(plot)
    local spawnPos = plot:GetSpawnCFrame() + Vector3.new(0, 5, 0)

	plot:Fired("Death", function()
		Death(spawnPos)
	end)
end)