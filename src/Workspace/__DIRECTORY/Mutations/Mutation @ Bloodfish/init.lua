--!strict

return {
	DisplayName = "Bloodfish",
	Color = Color3.fromRGB(151, 12, 12),
	MutationEarningsMultiplier = 2,
	ApplyToModel = function(model: Model)
		local Assets = game.ReplicatedStorage:WaitForChild("Assets")
		
		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("BasePart") then
				local part = obj :: BasePart
				local originalColor = part.Color
				
				-- Calculate brightness/lightness of original color
				local brightness = (originalColor.R + originalColor.G + originalColor.B) / 3
				
				-- White/light colors become pure red
				-- Darker colors become blackish red, but very dark colors get minimum red
				local redIntensity = brightness
				
				-- If color is very dark (close to black), give it a minimum red value
				if brightness < 0.15 then
					redIntensity = 0.15 -- Minimum red for very dark colors
				end
				
				local newColor = Color3.new(redIntensity, 0, 0)
				
				part.Color = newColor
			end
		end
	
		local vfxBox = model:FindFirstChild("VFX")
		if vfxBox and not vfxBox:GetAttribute("Added") then
			local particles = Assets:FindFirstChild("BloodMoon"):FindFirstChild("Particles")
			for _, particle in ipairs(particles:GetChildren()) do
				local cloned = particle:Clone()
				cloned.Parent = vfxBox
			end
			vfxBox:SetAttribute("Added", true)
		end
	end
}