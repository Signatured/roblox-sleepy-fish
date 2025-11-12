--!strict

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

-- Store original parent for each plot's ThirdFloor
local thirdFloorData: {[ClientPlot.Type]: {model: Model, originalParent: Instance?}} = {}

local function UpdateThirdFloorVisibility(plot: ClientPlot.Type)
	local data = thirdFloorData[plot]
	if not data then
		return
	end
	
	local extraFloors = plot:Save("ExtraFloors")
	
	if extraFloors and extraFloors >= 2 then
		-- Show the third floor
		if data.model.Parent == nil and data.originalParent then
			data.model.Parent = data.originalParent
		end
	else
		-- Hide the third floor
		if data.model.Parent ~= nil then
			data.originalParent = data.model.Parent
			data.model.Parent = nil
		end
	end
end

local function OnPlotCreated(plot: ClientPlot.Type)
	local model = plot:YieldModel()
	local thirdFloor = model:FindFirstChild("ThirdFloor")
	
	if not thirdFloor or not thirdFloor:IsA("Model") then
		return
	end
	
	-- Store the third floor data
	thirdFloorData[plot] = {
		model = thirdFloor,
		originalParent = thirdFloor.Parent,
	}
	
	-- Initialize visibility based on current ExtraFloors
	UpdateThirdFloorVisibility(plot)
	
	-- Listen for ExtraFloors changes
	plot:SaveUpdated("ExtraFloors"):Connect(function(_value: number?)
		UpdateThirdFloorVisibility(plot)
	end)
end

ClientPlot.OnAllAndCreated(OnPlotCreated)

ClientPlot.Destroying:Connect(function(plot: ClientPlot.Type)
	-- Clean up stored data
	if thirdFloorData[plot] then
		thirdFloorData[plot] = nil
	end
end)

