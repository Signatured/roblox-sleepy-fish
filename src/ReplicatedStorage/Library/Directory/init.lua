--!strict

export type schema = {
	Rarity: typeof(require(script.Rarity)),
	Gamepasses: typeof(require(script.Gamepasses)),
	Products: typeof(require(script.Products)),
    Fish: typeof(require(script.Fish)),
    Enemy: typeof(require(script.Enemy)),
}

local module: schema = {}::any

for _, child in pairs(script:GetChildren()) do
	if child:IsA("ModuleScript") then
		local success, result = pcall(require, child)
		if success then
			module[child.Name] = result
		else
			warn("Failed to require module:", child.Name, result)
		end
	end
end

return module
