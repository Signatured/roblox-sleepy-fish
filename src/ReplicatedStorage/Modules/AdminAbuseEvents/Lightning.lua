--!strict

--[[
	Client-side logic for Lightning event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local AdminAbuseEventCmds = require(ReplicatedStorage.Game.Library.Client.AdminAbuseEventCmds)
local Functions = require(ReplicatedStorage.Library.Functions)
local GUIFX = require(ReplicatedStorage.Library.Client.GUIFX)

local module = {}

-- Shared state for this event
local flashCount = 0
local _intensity = 0

function module.OnStart()
	print("[Lightning Client] Event started")
	flashCount = 0
	_intensity = 0
	
	NotificationCmds.Message("A storm is brewing...", {
		Color = Color3.fromRGB(100, 193, 255),
		Time = 8,
	})
	
	-- Register handler for lightning strikes
	AdminAbuseEventCmds.Fired("Lightning", "Strike", function(data: any?)
		if typeof(data) == "table" then
			local strikeData = data :: {
				UID: string?,
				StrikeCount: number?,
				StartPosition: Vector3?,
				EndPosition: Vector3?
			}
			-- Create visual effect
			if strikeData.StartPosition and strikeData.EndPosition then
				local startPos = strikeData.StartPosition
				local endPos = strikeData.EndPosition
				
				-- Find the LightningStrike template
				local assets = ReplicatedStorage:FindFirstChild("Assets")
				if assets then
					local adminEvents = assets:FindFirstChild("AdminEvents")
					if adminEvents then
						local lightning = adminEvents:FindFirstChild("Lightning")
						if lightning then
							local strikeTemplate = lightning:FindFirstChild("LightningStrike")
							if strikeTemplate then
								-- Clone the strike model
								local strike = strikeTemplate:Clone()
								
								-- Position the Hit part
								local hitPart = strike:FindFirstChild("Hit")
								if hitPart and hitPart:IsA("BasePart") then
									hitPart.Position = endPos
								end
								
								-- Resize and position the Beam part
								local beamPart = strike:FindFirstChild("Beam")
								if beamPart and beamPart:IsA("BasePart") then
									-- Calculate distance
									local distance = (endPos - startPos).Magnitude
									local midPoint = (startPos + endPos) / 2
									
									-- Beam needs to be 114 studs shorter (minimum 10)
									local beamLength = math.max(10, distance - 114)
									beamPart.Size = Vector3.new(5, beamLength, 5)
									
									-- Orient the beam so its Y-axis points from start to end
									local direction = (endPos - startPos).Unit
									
									-- Position at midpoint, then move up 57 studs
									local adjustedPosition = midPoint + Vector3.new(0, 57, 0)
									
									-- Create a CFrame at adjusted position with Y-axis pointing toward endPos
									beamPart.CFrame = CFrame.lookAt(adjustedPosition, adjustedPosition + direction) * CFrame.Angles(math.rad(90), 0, 0)
								end
								
								-- Parent to workspace
								strike.Parent = workspace.__THINGS.AdminEvents
								
								-- Emit all particles
								Functions.Emit(strike)

								-- Screen flash: only if hit part is on screen
								if hitPart then
									local camera = Workspace.CurrentCamera
									if camera then
										local _viewportPoint, onScreen = camera:WorldToViewportPoint(hitPart.Position)
										if onScreen then
											GUIFX.ScreenFlash(Functions.RandomDouble(0.05, 0.15), Functions.RandomDouble(0.3, 0.5), nil, Functions.RandomDouble(0.4, 0.6))
										end
									end
								end
								
								-- Disable particles after 1 second
								task.delay(0.1, function()
									for _, descendant in strike:GetDescendants() do
										if descendant:IsA("ParticleEmitter") then
											descendant.Enabled = false
										end
									end
								end)
								
								-- Destroy after 3 seconds total
								task.delay(3, function()
									strike:Destroy()
								end)
							else
								warn("[Lightning Client] LightningStrike model not found")
							end
						end
					end
				end
			end
		end
	end)
end

function module.RenderStepped(delta: number, time: number)
	-- Example: Gradually increase intensity over time
	_intensity = math.min(1, time / 30) -- Ramps up over 30 seconds
	
	-- Example: Flash effect every few seconds
	local currentFlash = math.floor(time / 3)
	if currentFlash > flashCount then
		flashCount = currentFlash
		-- Could trigger visual effects here
		-- print("[Lightning Client] Flash! Intensity:", _intensity)
	end
end

function module.OnStop()
	print("[Lightning Client] Event stopped. Total flashes:", flashCount)
	
	NotificationCmds.Message("The storm has passed...", {
		Color = Color3.fromRGB(100, 193, 255),
		Time = 8,
	})
	
	-- Reset state
	flashCount = 0
	_intensity = 0
end

return module

