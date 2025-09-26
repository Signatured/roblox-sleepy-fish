--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local _ContextActionService = game:GetService("ContextActionService")

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local Audio = require(game.ReplicatedStorage.Library.Audio)

-- Asset constants
local ASSET = "http://www.roblox.com/asset/?id="
local MESH_ROPE_TIP = ASSET .. "30308256"
local MESH_TOOL_DEFAULT = ASSET .. "33393806"
local HOOK_MESH_ID = ASSET .. "30307623"
local HOOK_TEXTURE_ID = ASSET .. "30307531"

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)

local COOLDOWN_SECONDS = 3
local GRAPPLE_RANGE = 27
local lastShotAt = 0
local blockedUids: {[string]: boolean} = {}

-- Track other players' grapples for replication
local otherGrapples: {[number]: { hookPart: BasePart, ropeAttachment: Attachment?, hookAttachment: Attachment, direction: Vector3, stop: boolean, tetherFishUid: string? }} = {}

local function getEquippedGrapple(): Tool?
	-- Prefer gadget system to verify equipped gadget
	local current: any = GadgetCmds.GetCurrent()
	local currentId = if typeof(current) == "string" then current elseif typeof(current) == "table" and current._id then current._id else nil
	if currentId ~= "Grappling Hook" then return nil end
	local character = localPlayer.Character
	if not character then return nil end
	return character:FindFirstChildOfClass("Tool")
end

local function getFishClickHit(input: InputObject): (Vector3?, Model?)
	local pos = input and input.Position
	if not camera or not pos then return nil, nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local root = workspace:FindFirstChild("__THINGS")
	local swimming = root and root:FindFirstChild("SwimmingFish")
	if not swimming then return nil, nil end
	params.FilterDescendantsInstances = { swimming }
	params.RespectCanCollide = false
	params.IgnoreWater = true
    local unitRay = camera:ScreenPointToRay(pos.X, pos.Y)
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
	if result and result.Instance then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		if model and model:GetAttribute("OceanFish") == true then
			return result.Position, model
		end
	end
	return nil, nil
end

local function shootGrapple(targetPosition: Vector3)
	local tool = getEquippedGrapple()
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then return end

	localPlayer:SetAttribute("Grappling", true)

	-- Notify server to replicate the shot (origin & direction) for other clients
	local origin = handle.Position
	local dir = (targetPosition - origin)
	if dir.Magnitude > 0 then dir = dir.Unit else dir = camera.CFrame.LookVector end
	Network.Fire("Grapple_Shoot", origin, dir)

	-- Play shoot sound on the local player's HumanoidRootPart
	local character = localPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		Audio.Play("rbxassetid://133240422241361", hrp)
	end

	-- Swap the tool's mesh to the rope tip
	local toolMesh = handle:FindFirstChildOfClass("SpecialMesh")
	if toolMesh and toolMesh:IsA("SpecialMesh") then
		(toolMesh :: SpecialMesh).MeshId = MESH_ROPE_TIP
	end

	-- Create the hook (a part with a SpecialMesh)
	local hookPart = Instance.new("Part")
	hookPart.Name = "GrappleHook"
	hookPart.Anchored = true
	hookPart.CanCollide = false
	hookPart.Size = Vector3.new(1, 1, 1)
	hookPart.Parent = Workspace

	local hookMesh = Instance.new("SpecialMesh")
	hookMesh.MeshType = Enum.MeshType.FileMesh
	hookMesh.MeshId = HOOK_MESH_ID
	hookMesh.TextureId = HOOK_TEXTURE_ID
	if toolMesh and toolMesh:IsA("SpecialMesh") then
		hookMesh.Scale = toolMesh.Scale
	else
		hookMesh.Scale = Vector3.new(1, 0.4, 1)
	end
	hookMesh.Parent = hookPart

	-- Create rope from Handle.RopeAttachment to hookPart
	local ropeAttachment0: Attachment? = (handle:FindFirstChild("RopeAttachment") :: Attachment)
	local hookAttachment = Instance.new("Attachment")
	hookAttachment.Name = "GrappleHookAttachment"
	hookAttachment.Parent = hookPart
	-- Offset to the back end of the hook (local +Z is back)
	hookAttachment.Position = Vector3.new(0, 0, 0.5)
	if ropeAttachment0 then
		local ropeBeam = Instance.new("Beam")
		ropeBeam.Attachment0 = ropeAttachment0
		ropeBeam.Attachment1 = hookAttachment
		ropeBeam.Color = ColorSequence.new(Color3.new(0, 0, 0))
		ropeBeam.Width0 = 0.06
		ropeBeam.Width1 = 0.06
		ropeBeam.CurveSize0 = 0
		ropeBeam.CurveSize1 = 0
		ropeBeam.Parent = hookPart
	end

	-- Initial CFrame 5 studs away toward click, looking at the click point
	local startPos = handle.Position + (targetPosition - handle.Position).Unit
	hookPart.CFrame = CFrame.new(startPos, targetPosition) * CFrame.Angles(0, 0, 0)

    -- Clear blocked UIDs
    blockedUids = {}

	-- Animate forward toward clicked position (clamped to GRAPPLE_RANGE studs), then back to handle
	-- Project the click along the camera ray and clamp so it is in front of the muzzle
	local camPos = camera.CFrame.Position
	local rayDir = (targetPosition - camPos)
	if rayDir.Magnitude == 0 then rayDir = camera.CFrame.LookVector else rayDir = rayDir.Unit end
	local tHit = (targetPosition - camPos):Dot(rayDir)
	local tMuzzle = (startPos - camPos):Dot(rayDir)
	local tClamped = math.max(tHit, tMuzzle + 0.1)
	local clampedTarget = camPos + rayDir * tClamped

	local toTarget = clampedTarget - startPos
	local direction = (toTarget.Magnitude > 0) and toTarget.Unit or camera.CFrame.LookVector
	local travel = math.min(GRAPPLE_RANGE, toTarget.Magnitude)
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
		local region = Region3.new(hookPart.Position - Vector3.new(2,2,2), hookPart.Position + Vector3.new(2,2,2))
		local ignore = {localPlayer.Character, hookPart}
		local parts = Workspace:FindPartsInRegion3WithIgnoreList(region, ignore, 50)
		for _, part in ipairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and model:GetAttribute("OceanFish") == true then
				local uidAttr = model:GetAttribute("UID")
				if typeof(uidAttr) == "string" and uidAttr ~= "" then
                    if blockedUids[uidAttr] then
                        break
                    end
                    blockedUids[uidAttr] = true
					-- Attempt to start grapple server-side
					local accepted = Network.Invoke("Grapple_HitFish", uidAttr) == true
					if accepted then
						local fishModel = model
						-- Tether: keep hook at the fish's leading edge while Grappling
						while hookPart and hookPart.Parent and fishModel and fishModel.Parent and not fishModel:GetAttribute("Carrying") do
							if fishModel:GetAttribute("Grappling") and fishModel:GetAttribute("Grappling") ~= localPlayer.UserId then break end
							local primary = fishModel.PrimaryPart or fishModel:FindFirstChildWhichIsA("BasePart")
							if not primary then break end
							local tipPos = primary.Position - direction * 1
							hookPart.CFrame = CFrame.new(tipPos, tipPos + direction)

							-- Cancel if player moved too far from the targeted fish
							local character2 = localPlayer.Character
							local hrp2 = character2 and character2:FindFirstChild("HumanoidRootPart")
							if hrp2 and hrp2:IsA("BasePart") then
								local distToFish = ((hrp2 :: BasePart).Position - primary.Position).Magnitude
								if distToFish > 45 then
									-- Cleanly end local grapple cycle
									local refreshTool3 = getEquippedGrapple()
									local refreshHandle3 = refreshTool3 and refreshTool3:FindFirstChild("Handle")
									local refreshMesh3 = refreshHandle3 and refreshHandle3:FindFirstChildOfClass("SpecialMesh")
									if refreshMesh3 and refreshMesh3:IsA("SpecialMesh") then
										(refreshMesh3 :: SpecialMesh).MeshId = MESH_TOOL_DEFAULT
									end
									localPlayer:SetAttribute("Grappling", nil)
									if hookPart then hookPart:Destroy() end
									Network.Fire("Grapple_Returned")
									pcall(function() GadgetCmds.EquipBestCoil() end)
									return
								end
							end
							RunService.Heartbeat:Wait()
						end
						-- Restore tool mesh on successful reel completion
						local refreshTool = getEquippedGrapple()
						local refreshHandle = refreshTool and refreshTool:FindFirstChild("Handle")
						local refreshMesh = refreshHandle and refreshHandle:FindFirstChildOfClass("SpecialMesh")
						if refreshMesh and refreshMesh:IsA("SpecialMesh") then
							(refreshMesh :: SpecialMesh).MeshId = MESH_TOOL_DEFAULT
						end
						localPlayer:SetAttribute("Grappling", nil)
						if hookPart then hookPart:Destroy() end
						GadgetCmds.EquipBestCoil()
						return
					else
						-- Not accepted: remain blocked until hook finishes its return
						break
					end
				end
			end
		end
	end

	-- Return toward the tool's CURRENT RopeAttachment over 1 second using time-based Lerp
	local returnDuration = 1
	local elapsed = 0
	local ropeAttachment: Attachment? = (handle:FindFirstChild("RopeAttachment") :: Attachment)
	local returnStartPos = hookPart.Position
	while elapsed < returnDuration and hookPart and hookPart.Parent do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		local alpha = math.clamp(elapsed / returnDuration, 0, 1)
		local targetPos = ropeAttachment and ropeAttachment.WorldPosition or handle.Position
		local lerpPos = returnStartPos:Lerp(targetPos, alpha)
		hookPart.CFrame = CFrame.new(lerpPos, lerpPos + direction)
	end
	-- Ensure final placement at the attachment after the 1s window
	if hookPart and hookPart.Parent then
		local finalPos = (ropeAttachment and ropeAttachment.WorldPosition) or handle.Position
		hookPart.CFrame = CFrame.new(finalPos, finalPos + direction)
	end

	-- Restore tool mesh on full cycle completion
	local refreshTool2 = getEquippedGrapple()
	local refreshHandle2 = refreshTool2 and refreshTool2:FindFirstChild("Handle")
	local refreshMesh2 = refreshHandle2 and refreshHandle2:FindFirstChildOfClass("SpecialMesh")
	if refreshMesh2 and refreshMesh2:IsA("SpecialMesh") then
		(refreshMesh2 :: SpecialMesh).MeshId = MESH_TOOL_DEFAULT
	end

	localPlayer:SetAttribute("Grappling", nil)
	-- Signal server that this cycle ended without an attach so others stop visuals
	Network.Fire("Grapple_Returned")

	hookPart:Destroy()
end

local function onFireGrapple(input: InputObject)
	-- Cooldown gate
	local now = Workspace:GetServerTimeNow()
	if now - lastShotAt < COOLDOWN_SECONDS then return end

	local tool = getEquippedGrapple()
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then return end
	local ropeAttachment: Attachment? = (handle:FindFirstChild("RopeAttachment") :: Attachment)

	local hitPos, fishModel = getFishClickHit(input)
	if not hitPos or not fishModel then
		NotificationCmds.Message("You need to click a fish to pull!", { Color = Color3.fromRGB(255, 0, 0) })
		return
	end

	local originPos = ropeAttachment and ropeAttachment.WorldPosition or handle.Position
	if (hitPos - originPos).Magnitude > GRAPPLE_RANGE then
		NotificationCmds.Message("That fish is out of range!", { Color = Color3.fromRGB(255, 0, 0) })
		return
	end

	lastShotAt = now
	shootGrapple(hitPos)
end

-- Connect inputs: mouse and touch
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		onFireGrapple(input)
	end
end)

-- Render other players' shots
Network.Fired("Grapple_PlayShot", function(userId: number, origin: Vector3, direction: Vector3)
	if typeof(userId) ~= "number" or userId == Players.LocalPlayer.UserId then return end
	-- Find their tool handle (best effort)
	local other = Players:GetPlayerByUserId(userId)
	local character = other and other.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	local ropeAttachment = handle and handle:FindFirstChild("RopeAttachment")
	-- Swap their tool mesh to rope tip during the shot
	local otherMesh = handle and handle:FindFirstChildOfClass("SpecialMesh")
	if otherMesh and otherMesh:IsA("SpecialMesh") then
		(otherMesh :: SpecialMesh).MeshId = MESH_ROPE_TIP
	end

	-- Spawn a proxy hook and beam for their shot
	local hookPart = Instance.new("Part")
	hookPart.Name = "GrappleHookProxy"
	hookPart.Anchored = true
	hookPart.CanCollide = false
	hookPart.Size = Vector3.new(1, 1, 1)
	hookPart.Parent = Workspace

	-- Play shoot sound on the other player's HumanoidRootPart
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		Audio.Play("rbxassetid://133240422241361", hrp)
	end

	local hookMesh = Instance.new("SpecialMesh")
	hookMesh.MeshType = Enum.MeshType.FileMesh
	hookMesh.MeshId = HOOK_MESH_ID
	hookMesh.TextureId = HOOK_TEXTURE_ID
	hookMesh.Scale = Vector3.new(1, 0.4, 1)
	hookMesh.Parent = hookPart

	local hookAttachment = Instance.new("Attachment")
	hookAttachment.Name = "GrappleHookAttachment"
	hookAttachment.Parent = hookPart
	hookAttachment.Position = Vector3.new(0, 0, 0.5)

	if ropeAttachment and ropeAttachment:IsA("Attachment") then
		local ropeBeam = Instance.new("Beam")
		ropeBeam.Attachment0 = ropeAttachment
		ropeBeam.Attachment1 = hookAttachment
		ropeBeam.Color = ColorSequence.new(Color3.new(0, 0, 0))
		ropeBeam.Width0 = 0.06
		ropeBeam.Width1 = 0.06
		ropeBeam.CurveSize0 = 0
		ropeBeam.CurveSize1 = 0
		ropeBeam.Parent = hookPart
	end

	local startPos = origin + direction.Unit
	hookPart.CFrame = CFrame.new(startPos, startPos + direction)

	-- store state
	otherGrapples[userId] = {
		hookPart = hookPart,
		ropeAttachment = ropeAttachment and ropeAttachment:IsA("Attachment") and (ropeAttachment :: Attachment) or nil,
		hookAttachment = hookAttachment,
		direction = direction.Unit,
		stop = false,
		tetherFishUid = nil,
	}

	-- fly GRAPPLE_RANGE studs over 1s then return 1s unless attach happens
	task.spawn(function()
		local travel = GRAPPLE_RANGE
		local forwardDuration = 1
		local fSpeed = travel / forwardDuration
		local fElapsed = 0
		while fElapsed < forwardDuration and hookPart.Parent do
			local rec = otherGrapples[userId]
			if not rec or rec.stop or rec.tetherFishUid then break end
			local dt = RunService.Heartbeat:Wait()
			fElapsed += dt
			hookPart.CFrame = CFrame.new(hookPart.Position + direction.Unit * (fSpeed * dt), hookPart.Position + direction.Unit)
		end
		-- Return to handle attachment (if exists) using Lerp over 1s unless attach happened
		local rec = otherGrapples[userId]
		if not rec or rec.stop or rec.tetherFishUid then return end
		local returnDuration = 1
		local elapsed = 0
		local returnStart = hookPart.Position
		while elapsed < returnDuration and hookPart.Parent do
			local rec2 = otherGrapples[userId]
			if not rec2 or rec2.stop or rec2.tetherFishUid then return end
			local dt = RunService.Heartbeat:Wait()
			elapsed += dt
			local alpha = math.clamp(elapsed / returnDuration, 0, 1)
			local targetPos = (ropeAttachment and ropeAttachment:IsA("Attachment") and (ropeAttachment :: Attachment).WorldPosition) or (handle and handle.Position) or startPos
			local pos = returnStart:Lerp(targetPos, alpha)
			hookPart.CFrame = CFrame.new(pos, pos + direction)
		end
		if hookPart.Parent then hookPart:Destroy() end
		otherGrapples[userId] = nil
	end)
end)

-- On attach, tether the proxy hook to the fish until server clears
Network.Fired("Grapple_Attach", function(userId: number, uid: string)
	if typeof(userId) ~= "number" or userId == Players.LocalPlayer.UserId then return end
	local rec = otherGrapples[userId]
	if not rec or not rec.hookPart or not rec.hookPart.Parent then return end
	rec.tetherFishUid = uid
	local function findFishByUid(): Model?
		local things = workspace:FindFirstChild("__THINGS")
		local swimming = things and things:FindFirstChild("SwimmingFish")
		if not swimming then return nil end
		for _, m in ipairs(swimming:GetDescendants()) do
			if m:IsA("Model") and m:GetAttribute("UID") == uid then
				return m
			end
		end
		return nil
	end
	task.spawn(function()
		local fish = findFishByUid()
		if not fish then return end
		local dir = rec.direction
		while rec and rec.hookPart and rec.hookPart.Parent and fish and fish.Parent do
			if fish:GetAttribute("Grappling") and fish:GetAttribute("Grappling") ~= userId then break end
			local primary = fish.PrimaryPart or fish:FindFirstChildWhichIsA("BasePart")
			if not primary then break end
			local tipPos = primary.Position - dir.Unit * 1
			rec.hookPart.CFrame = CFrame.new(tipPos, tipPos + dir)
			RunService.Heartbeat:Wait()
		end
		if rec and rec.hookPart then pcall(function() rec.hookPart:Destroy() end) end
		otherGrapples[userId] = nil
	end)
end)

-- End other players' visuals early (on attach finish or no-hit finish)
Network.Fired("Grapple_End", function(userId: number)
	if typeof(userId) ~= "number" or userId == Players.LocalPlayer.UserId then return end
	local rec = otherGrapples[userId]
	if rec then rec.stop = true end
	-- Best-effort cleanup: destroy any proxy hooks for this user
	for _, inst in ipairs(Workspace:GetChildren()) do
		if inst:IsA("BasePart") and inst.Name == "GrappleHookProxy" then
			inst:Destroy()
		end
	end
	-- Restore their tool mesh to default
	local other = Players:GetPlayerByUserId(userId)
	local character = other and other.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	local mesh = handle and handle:FindFirstChildOfClass("SpecialMesh")
	if mesh and mesh:IsA("SpecialMesh") then
		(mesh :: SpecialMesh).MeshId = MESH_TOOL_DEFAULT
	end
	otherGrapples[userId] = nil
end)

-- Stop local grappling immediately if player is tagged Dead
localPlayer:GetAttributeChangedSignal("Dead"):Connect(function()
	if localPlayer:GetAttribute("Dead") == true and localPlayer:GetAttribute("Grappling") then
		-- Destroy any local hook part
		for _, inst in ipairs(Workspace:GetChildren()) do
			if inst:IsA("BasePart") and inst.Name == "GrappleHook" then
				inst:Destroy()
			end
		end
		-- Restore tool mesh
		local tool = getEquippedGrapple()
		local handle = tool and tool:FindFirstChild("Handle")
		local mesh = handle and handle:FindFirstChildOfClass("SpecialMesh")
		if mesh and mesh:IsA("SpecialMesh") then
			(mesh :: SpecialMesh).MeshId = MESH_TOOL_DEFAULT
		end
		-- Clear state and notify server to end cycle
		localPlayer:SetAttribute("Grappling", nil)
		Network.Fire("Grapple_Returned")
		-- Equip best coil to ensure visuals/tool reset
		local ok = pcall(function()
			GadgetCmds.EquipBestCoil()
		end)
		ok = ok -- silence
	end
end)

return {}


