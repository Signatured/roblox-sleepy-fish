--!strict

--[[
	Client-side logic for Lightning event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
			print("[Lightning Client] Lightning struck fish:", strikeData.UID, "Strike #" .. tostring(strikeData.StrikeCount or 0))
			
			-- Create visual effect
			if strikeData.StartPosition and strikeData.EndPosition then
				local startPos = strikeData.StartPosition
				local endPos = strikeData.EndPosition
				
				print("[Lightning Client] Strike positions - Start:", startPos, "End:", endPos)
				print("[Lightning Client] Distance:", (endPos - startPos).Magnitude)
				
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
									print("[Lightning Client] Hit part positioned at:", hitPart.Position)
									print("[Lightning Client] Hit position difference from end:", (hitPart.Position - endPos).Magnitude)
								end
								
								-- Resize and position the Beam part
								local beamPart = strike:FindFirstChild("Beam")
								if beamPart and beamPart:IsA("BasePart") then
									-- Calculate distance
									local distance = (endPos - startPos).Magnitude
									local midPoint = (startPos + endPos) / 2
									
									print("[Lightning Client] Calculated midpoint:", midPoint)
									print("[Lightning Client] Calculated distance:", distance)
									
									-- Original size is 5, 243.896, 5 (Y is the length)
									-- Resize to match the strike distance
									beamPart.Size = Vector3.new(5, distance, 5)
									
									-- Orient the beam so its Y-axis points from start to end
									-- The beam's Y-axis is its length, so it should point downward
									local direction = (endPos - startPos).Unit
									
									-- Create a CFrame at midpoint with Y-axis pointing toward endPos
									-- We use lookAt which points -Z, then rotate 90° around X to make Y point that way
									beamPart.CFrame = CFrame.lookAt(midPoint, midPoint + direction) * CFrame.Angles(math.rad(90), 0, 0)
									
									print("[Lightning Client] Beam size:", beamPart.Size)
									print("[Lightning Client] Beam CFrame position:", beamPart.CFrame.Position)
									print("[Lightning Client] Beam CFrame lookVector:", beamPart.CFrame.LookVector)
									print("[Lightning Client] Beam CFrame upVector:", beamPart.CFrame.UpVector)
									
									-- Verify the top and bottom of the beam
									local halfHeight = distance / 2
									local topPos = beamPart.CFrame * Vector3.new(0, halfHeight, 0)
									local bottomPos = beamPart.CFrame * Vector3.new(0, -halfHeight, 0)
									print("[Lightning Client] Beam top should be at:", startPos, "actual:", topPos)
									print("[Lightning Client] Beam bottom should be at:", endPos, "actual:", bottomPos)
									print("[Lightning Client] Top difference:", (topPos - startPos).Magnitude)
									print("[Lightning Client] Bottom difference:", (bottomPos - endPos).Magnitude)
								end
								
								-- Parent to workspace
								strike.Parent = workspace.__THINGS.AdminEvents
								
								-- Emit all particles
								Functions.Emit(strike)

								GUIFX.ScreenFlash(Functions.RandomDouble(0.05, 0.15), Functions.RandomDouble(0.2, 0.35), nil, Functions.RandomDouble(0.2, 0.5))
								
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

