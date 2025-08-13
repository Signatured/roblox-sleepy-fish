--!strict

--[[
	This script automatically loads all command modules in this directory.
	This makes adding new commands as simple as creating a new file.
]]

for _, commandModule in ipairs(script:GetChildren()) do
	if commandModule:IsA("ModuleScript") and commandModule.Name ~= "init" then
		task.spawn(require, commandModule)
	end
end

-- Return an empty table to satisfy the require() contract.
return {} 