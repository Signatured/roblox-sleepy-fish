--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local GadgetCmds = require(game.ReplicatedStorage.Game.Library.Client.GadgetCmds)

-- Asset constants
local ASSET = "http://www.roblox.com/asset/?id="
local MESH_ROPE_TIP = ASSET .. "30308256"
local MESH_TOOL_DEFAULT = ASSET .. "33393806"
local HOOK_MESH_ID = ASSET .. "30307623"
local HOOK_TEXTURE_ID = ASSET .. "30307531"

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

	-- Initial CFrame 5 studs away toward click, looking at the click point
	local startPos = handle.Position + (targetPosition - handle.Position).Unit
	hookPart.CFrame = CFrame.new(startPos, targetPosition) * CFrame.Angles(0, 0, 0)

    -- Clear blocked UIDs
    blockedUids = {}

	-- Animate forward toward clicked position (clamped to 30 studs), then back to handle
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
	local travel = math.min(30, toTarget.Magnitude)
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
							RunService.Heartbeat:Wait()
						end
						-- Restore tool mesh on successful reel completion
						local refreshTool = getEquippedGrapple()
						local refreshHandle = refreshTool and refreshTool:FindFirstChild("Handle")
						local refreshMesh = refreshHandle and refreshHandle:FindFirstChildOfClass("SpecialMesh")
						if refreshMesh and refreshMesh:IsA("SpecialMesh") then
							(refreshMesh :: SpecialMesh).MeshId = MESH_TOOL_DEFAULT
						end
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
	if (hitPos - originPos).Magnitude > 30 then
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

return {}


