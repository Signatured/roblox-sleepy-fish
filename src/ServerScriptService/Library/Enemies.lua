--!strict

-- Server module that spawns enemies and manages their targeting/return logic.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local EnemyTypes = require(ReplicatedStorage.Game.Library.Types.Enemy)

local ROOT = workspace:WaitForChild("__THINGS")
local ENEMY_LOCATIONS = ROOT:WaitForChild("EnemyLocations")

local ENEMY_CONTAINER = ROOT:FindFirstChild("Enemies")
if not ENEMY_CONTAINER then
	ENEMY_CONTAINER = Instance.new("Folder")
	ENEMY_CONTAINER.Name = "Enemies"
	ENEMY_CONTAINER.Parent = ROOT
end

type EnemyState = "Idle" | "Chasing" | "Returning"

type EnemyRecord = {
	Id: string,
	Schema: EnemyTypes.dir_schema,
	Model: Model,
	SpawnCFrame: CFrame,
	State: EnemyState,
	TargetPlayer: Player?,
    TargetFromAlert: boolean?,
    TargetAttachment: Attachment?,
	LinearVelocity: LinearVelocity?,
	AlignOrientation: AlignOrientation?,
	Attachment: Attachment?,
}

local Enemies = {}

local ATTACK_RANGE = 10
local MOVE_SPEED = 20

local enemies: { [string]: EnemyRecord } = {}

-- Alert queue populated by fish pickup events
local pendingAlerts: { {player: Player, position: Vector3, radius: number, t: number} } = {}

local function getPrimaryPart(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function setAssemblyAnchored(model: Model, anchored: boolean)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Anchored = anchored
		end
	end
end

local function ensureMotionConstraints(rec: EnemyRecord)
    local primary = getPrimaryPart(rec.Model)
    if not primary then return end

    if not rec.Attachment then
        local newAttachment = Instance.new("Attachment")
        newAttachment.Name = "EnemyPrimaryAttachment"
        newAttachment.Parent = primary
        rec.Attachment = newAttachment
    end

    if not rec.AlignOrientation then
        local newAO = Instance.new("AlignOrientation")
        newAO.Name = "EnemyAlignOrientation"
        newAO.Parent = primary
        rec.AlignOrientation = newAO
    end

    local attachment: Attachment = rec.Attachment :: Attachment
    local ao: AlignOrientation = rec.AlignOrientation :: AlignOrientation

    ao.Attachment0 = attachment
    ao.MaxTorque = 1e9
    ao.Responsiveness = 200
    ao.RigidityEnabled = true
    (ao :: any).Mode = Enum.OrientationAlignmentMode.OneAttachment

    if not rec.LinearVelocity then
        local lv = Instance.new("LinearVelocity")
        lv.Name = "EnemyLinearVelocity"
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.Attachment0 = attachment
        lv.MaxForce = 99999999999
        lv.Parent = primary
        rec.LinearVelocity = lv
    else
        local lv = rec.LinearVelocity :: LinearVelocity
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.Attachment0 = attachment
        lv.Parent = primary
    end
end

local function clearMotionConstraints(rec: EnemyRecord)
	if rec.AlignOrientation then rec.AlignOrientation:Destroy() end
	if rec.LinearVelocity then rec.LinearVelocity:Destroy() end
	if rec.Attachment then rec.Attachment:Destroy() end
	rec.AlignOrientation = nil
	rec.LinearVelocity = nil
	rec.Attachment = nil
end

local function beginChasing(rec: EnemyRecord, player: Player, fromAlert: boolean)
    print("beginChasing", rec.Id, player.Name)
	rec.TargetPlayer = player
	rec.TargetFromAlert = fromAlert
	rec.State = "Chasing"
    local primary = getPrimaryPart(rec.Model)
	if not primary then return end
	-- Unanchor per spec (primary part)
	setAssemblyAnchored(rec.Model, false)
	ensureMotionConstraints(rec)
    -- Ensure server controls physics so orientation updates apply reliably
    -- Force server ownership of physics if available
    local pp = primary :: BasePart
    if (pp.SetNetworkOwner) then
        pp:SetNetworkOwner(nil)
    end

    -- Ensure orientation uses lookAt (not target orientation)
    local ao: AlignOrientation? = rec.AlignOrientation
    if ao then (ao :: AlignOrientation).Attachment1 = nil end
    rec.TargetAttachment = nil
end

local function beginReturning(rec: EnemyRecord)
	rec.TargetPlayer = nil
	rec.State = "Returning"
    local primary = getPrimaryPart(rec.Model)
	if not primary then return end
    setAssemblyAnchored(rec.Model, false)
	ensureMotionConstraints(rec)
    local pp = primary :: BasePart
    if (pp.SetNetworkOwner) then
        pp:SetNetworkOwner(nil)
    end
end

local function anchorAndIdle(rec: EnemyRecord)
	setAssemblyAnchored(rec.Model, true)
	clearMotionConstraints(rec)
	rec.TargetPlayer = nil
    rec.TargetAttachment = nil
	rec.State = "Idle"
end

local function tryAdoptAlert(rec: EnemyRecord)
	local primary = getPrimaryPart(rec.Model)
	if not primary then return end
	for i = #pendingAlerts, 1, -1 do
		local alert = pendingAlerts[i]
		local dist = (primary.Position - alert.position).Magnitude
		if dist <= alert.radius then
			beginChasing(rec, alert.player, true)
			table.remove(pendingAlerts, i)
			return
		end
	end
end

local function findNearbyPlayer(rec: EnemyRecord): Player?
	local primary = getPrimaryPart(rec.Model)
	if not primary then return nil end
	local followRange = rec.Schema.FollowRange or 0
	local closest: Player? = nil
	local closestDist = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local d = (primary.Position - hrp.Position).Magnitude
			if d <= followRange and d < closestDist then
				closest = player
				closestDist = d
			end
		end
	end
	return closest
end

-- Per-frame update
RunService.Heartbeat:Connect(function()
    for _, rec in pairs(enemies) do
        local primary = getPrimaryPart(rec.Model)
        if not primary then continue end
        local primaryPart: BasePart = primary :: BasePart

		if rec.State == "Idle" then
			-- Wait for alerts to start chase
			tryAdoptAlert(rec)
		elseif rec.State == "Chasing" then
			local target = rec.TargetPlayer
			local character = target and target.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not target or not hrp or not humanoid or humanoid.Health <= 0 then
				-- Target lost; try follow someone else
				local nearby = findNearbyPlayer(rec)
				if nearby then
					beginChasing(rec, nearby, false)
				else
					beginReturning(rec)
				end
            else
                -- Constant-speed homing using LinearVelocity; orientation via AlignOrientation
                local lv = rec.LinearVelocity
                local ao = rec.AlignOrientation
                local hrpPart: BasePart = hrp :: BasePart
                local toTarget = hrpPart.Position - primaryPart.Position
                local d = toTarget.Magnitude
                local dir = if d > 0 then toTarget / d else Vector3.zero
                if lv then (lv :: LinearVelocity).VectorVelocity = dir * MOVE_SPEED end
                if ao then
                    local forward = dir
                    local up = Vector3.yAxis
                    local lookCFrame
                    if forward.Magnitude > 0 then
                        lookCFrame = CFrame.lookAt(primaryPart.Position, primaryPart.Position + forward, up)
                    else
                        lookCFrame = primaryPart.CFrame
                    end
                    (ao :: AlignOrientation).CFrame = lookCFrame
                end
				-- If this target was acquired via FollowRange, drop if they exit FollowRange
				if not rec.TargetFromAlert then
					local followRange = rec.Schema.FollowRange or 0
					if d > followRange then
						beginReturning(rec)
						continue
					end
				end
				if d <= ATTACK_RANGE then
					(humanoid :: Humanoid).Health = 0
				end
			end
			-- Alerts can override follow while chasing (ignore FollowRange)
			-- If a new alert is close, switch target to that player
            for i = #pendingAlerts, 1, -1 do
                local alert = pendingAlerts[i]
                local dist = (primaryPart.Position - alert.position).Magnitude
				if dist <= alert.radius then
					beginChasing(rec, alert.player, true)
					table.remove(pendingAlerts, i)
					break
				end
			end
		elseif rec.State == "Returning" then
			-- Look for a nearby player to follow while returning
			local nearby = findNearbyPlayer(rec)
			if nearby then
				beginChasing(rec, nearby, false)
            else
                -- Head back to spawn at constant speed
                local lv = rec.LinearVelocity
                local ao = rec.AlignOrientation
                local toHome = rec.SpawnCFrame.Position - primaryPart.Position
                local dHome = toHome.Magnitude
                local dir = if dHome > 0 then toHome / dHome else Vector3.zero
                if lv then (lv :: LinearVelocity).VectorVelocity = dir * MOVE_SPEED end
                if ao then
                    local forward = dir
                    local up = Vector3.yAxis
                    local lookCFrame
                    if forward.Magnitude > 0 then
                        lookCFrame = CFrame.lookAt(primaryPart.Position, primaryPart.Position + forward, up)
                    else
                        lookCFrame = primaryPart.CFrame
                    end
                    (ao :: AlignOrientation).CFrame = lookCFrame
                end
				-- Check arrival
				if dHome <= 3 then
					anchorAndIdle(rec)
				end
				-- Alerts can interrupt return anytime
				tryAdoptAlert(rec)
			end
		end
	end
end)

-- Public API
function Enemies.Alert(player: Player, position: Vector3, radius: number)
	-- Add an alert entry; enemies will check range and adopt target if close
	table.insert(pendingAlerts, { player = player, position = position, radius = radius, t = os.clock() })
end

-- Spawn all enemies from Directory.Enemy
for id, dir in pairs(Directory.Enemy) do
	local modelTemplate = dir._script:WaitForChild("Model")
	if not modelTemplate or not modelTemplate:IsA("Model") then
		warn("[Enemies] Model missing for", id)
		continue
	end
	local spawnPart = ENEMY_LOCATIONS:FindFirstChild(tostring(dir.Location))
	if not spawnPart or not spawnPart:IsA("BasePart") then
		warn("[Enemies] Spawn location not found for", id, "location:", dir.Location)
		continue
	end
	local clone = modelTemplate:Clone()
	clone:PivotTo(spawnPart.CFrame)
	setAssemblyAnchored(clone, true)
	clone.Parent = ENEMY_CONTAINER

	local rec: EnemyRecord = {
		Id = id,
		Schema = dir,
		Model = clone,
		SpawnCFrame = spawnPart.CFrame,
		State = "Idle",
		TargetPlayer = nil,
		LinearVelocity = nil,
		AlignOrientation = nil,
		Attachment = nil,
	}

	enemies[id] = rec
end

return Enemies


