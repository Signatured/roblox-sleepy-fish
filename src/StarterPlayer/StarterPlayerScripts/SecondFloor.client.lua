--!strict

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

-- Store original parent for each plot's SecondFloor
local secondFloorData: {[ClientPlot.Type]: {model: Model, originalParent: Instance?}} = {}

local function UpdateSecondFloorVisibility(plot: ClientPlot.Type)
	local data = secondFloorData[plot]
	if not data then
		return
	end
	
	local extraFloors = plot:Save("ExtraFloors")
	
	-- Show if ExtraFloors >= 1, hide if nil or < 1
	if extraFloors and extraFloors >= 1 then
		-- Show the second floor
		if data.model.Parent == nil and data.originalParent then
			data.model.Parent = data.originalParent
		end
	else
		-- Hide the second floor
		if data.model.Parent ~= nil then
			data.originalParent = data.model.Parent
			data.model.Parent = nil
		end
	end
end

local function OnPlotCreated(plot: ClientPlot.Type)
	local model = plot:YieldModel()
	local secondFloor = model:FindFirstChild("SecondFloor")
	
	if not secondFloor or not secondFloor:IsA("Model") then
		return
	end
	
	-- Store the second floor data
	secondFloorData[plot] = {
		model = secondFloor,
		originalParent = secondFloor.Parent,
	}
	
	-- Initialize visibility based on current ExtraFloors
	UpdateSecondFloorVisibility(plot)
	
	-- Listen for ExtraFloors changes
	plot:SaveUpdated("ExtraFloors"):Connect(function(_value: number?)
		UpdateSecondFloorVisibility(plot)
	end)
end

ClientPlot.OnAllAndCreated(OnPlotCreated)

ClientPlot.Destroying:Connect(function(plot: ClientPlot.Type)
	-- Clean up stored data
	if secondFloorData[plot] then
		secondFloorData[plot] = nil
	end
end)

