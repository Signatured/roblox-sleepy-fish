--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local _TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Network = require(game.ReplicatedStorage.Library.Client.Network)

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)

local COOLDOWN_SECONDS = 4
local lastShotAt = 0
local blockedUids: {[string]: boolean} = {}

local function getEquippedGrapple(): Tool?
	-- Prefer gadget system to verify equipped gadget
	local current: any = GadgetCmds.GetCurrent()
	local currentId = if typeof(current) == "string" then current elseif typeof(current) == "table" and current._id then current._id else nil
	if currentId ~= "Grappling Hook" then return nil end
	local character = localPlayer.Character
	if not character then return nil end
	return character:FindFirstChildOfClass("Tool")
end

local function getMouseWorldPosition(input: InputObject?): Vector3?
	-- Prefer Mouse.Hit for desktop
	local mouse = localPlayer:GetMouse()
	if not input or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local hit = mouse and mouse.Hit
		if hit then return hit.Position end
	end

	-- Fallback: ray from screen point
	local pos = input and input.Position
	if not camera or not pos then return nil end
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { localPlayer.Character or Workspace }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if result then
		return result.Position
	end
	return ray.Origin + ray.Direction * 100
end

local function shootGrapple(targetPosition: Vector3)
	local tool = getEquippedGrapple()
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then return end

	-- Per-shot state
	local lastTriedUid: string? = nil

	-- Swap the tool's mesh to the rope tip
	local toolMesh = handle:FindFirstChildOfClass("SpecialMesh")
	if toolMesh and toolMesh:IsA("SpecialMesh") then
		(toolMesh :: SpecialMesh).MeshId = "http://www.roblox.com/asset/?id=30308256"
	end

	-- Create the hook (a part with a SpecialMesh)
	local hookPart = Instance.new("Part")
	-- defensive: ensure a previous cycle's uid isn't left blocked
	if lastTriedUid and blockedUids[lastTriedUid] then
		blockedUids[lastTriedUid] = nil
		lastTriedUid = nil
	end
	hookPart.Name = "GrappleHook"
	hookPart.Anchored = true
	hookPart.CanCollide = false
	hookPart.Size = Vector3.new(1, 1, 1)
	hookPart.Parent = Workspace

	local hookMesh = Instance.new("SpecialMesh")
	hookMesh.MeshType = Enum.MeshType.FileMesh
	hookMesh.MeshId = "http://www.roblox.com/asset/?id=30307623"
	hookMesh.TextureId = "http://www.roblox.com/asset/?id=30307531"
	if toolMesh and toolMesh:IsA("SpecialMesh") then
		hookMesh.Scale = toolMesh.Scale
	else
		hookMesh.Scale = Vector3.new(1, 0.4, 1)
	end
	hookMesh.Parent = hookPart

	-- Initial CFrame 5 studs away toward click, looking at the click point
	local startPos = handle.Position + (targetPosition - handle.Position).Unit
	hookPart.CFrame = CFrame.new(startPos, targetPosition) * CFrame.Angles(0, 0, 0)

	-- Animate forward toward clicked position (clamped to 30 studs), then back to handle
	local toTarget = targetPosition - startPos
	-- Use spawn-to-click direction; if pointing toward the camera, flip it away
	local direction = (toTarget.Magnitude > 0) and toTarget.Unit or camera.CFrame.LookVector
	if direction:Dot(camera.CFrame.LookVector) < 0 then
		direction = -direction
	end
	-- Railgun-style: always travel exactly 30 studs from the starting position along the click direction
	local travel = 30
	local _forwardGoalPos = startPos + direction * travel
	-- Step forward manually to detect hits
	local forwardDuration = 1
	local fElapsed = 0
	local fSpeed = (travel / forwardDuration)
	while fElapsed < forwardDuration and hookPart and hookPart.Parent do
		local dt = RunService.Heartbeat:Wait()
		fElapsed += dt
		local step = fSpeed * dt
		local nextPos = hookPart.Position + direction * step
		local nextCF = CFrame.new(nextPos, nextPos + direction)
		hookPart.CFrame = nextCF
		-- Detect overlap with fish
		local region = Region3.new(hookPart.Position - Vector3.new(1,1,1), hookPart.Position + Vector3.new(1,1,1))
		local ignore = {localPlayer.Character, hookPart}
		local parts = Workspace:FindPartsInRegion3WithIgnoreList(region, ignore, 50)
		for _, part in ipairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and model:GetAttribute("OceanFish") == true then
				local uidAttr = model:GetAttribute("UID")
				if typeof(uidAttr) == "string" and uidAttr ~= "" then
					if blockedUids[uidAttr] then
						-- already attempted this fish during current cycle
						break
					end
					blockedUids[uidAttr] = true
					lastTriedUid = uidAttr
					-- Attempt to start grapple server-side
					local accepted = Network.Invoke("Grapple_HitFish", uidAttr) == true
					if accepted then
						local fishModel = model
						-- Tether: keep hook at the fish's leading edge while Grappling
						while hookPart and hookPart.Parent and fishModel and fishModel.Parent do
							if fishModel:GetAttribute("Grappling") and fishModel:GetAttribute("Grappling") ~= localPlayer.UserId then break end
							local primary = fishModel.PrimaryPart or fishModel:FindFirstChildWhichIsA("BasePart")
							if not primary then break end
							local tipPos = primary.Position - direction * 1
							hookPart.CFrame = CFrame.new(tipPos, tipPos + direction)
							RunService.Heartbeat:Wait()
						end
						blockedUids[uidAttr] = nil
						if hookPart then hookPart:Destroy() end
						return
					else
						-- Not accepted: remain blocked until hook finishes its return
						break
					end
				end
			end
		end
	end

	-- Return toward the tool's CURRENT position over 1 second, updating target each frame
	local returnDuration = 1
	local speed = (travel > 0 and travel or 30) / returnDuration
	local elapsed = 0
	while elapsed < returnDuration and hookPart and hookPart.Parent do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local currentHandlePos = handle.Position
		local toHandle = currentHandlePos - hookPart.Position
		local step = speed * dt
		if toHandle.Magnitude <= step then
			hookPart.CFrame = CFrame.new(currentHandlePos, currentHandlePos + direction)
			break
		else
			local dirStep = toHandle.Unit * step
			local nextPos = hookPart.Position + dirStep
			hookPart.CFrame = CFrame.new(nextPos, nextPos + direction)
		end
	end

	-- End of cycle: clear any blocked UID from this attempt
	if lastTriedUid and blockedUids[lastTriedUid] then
		blockedUids[lastTriedUid] = nil
	end

	hookPart:Destroy()
end

local function onFireGrapple(input: InputObject)
	-- Cooldown gate
	local now = Workspace:GetServerTimeNow()
	if now - lastShotAt < COOLDOWN_SECONDS then return end

	if not getEquippedGrapple() then return end
	local pos = getMouseWorldPosition(input)
	if not pos then return end
	lastShotAt = now
	shootGrapple(pos)
end

-- Connect inputs: mouse and touch
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		onFireGrapple(input)
	end
end)

return {}


