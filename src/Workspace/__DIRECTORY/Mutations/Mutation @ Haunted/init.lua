--!strict

return {
	DisplayName = "Haunted",
	Color = Color3.fromRGB(80, 42, 119),
	MutationEarningsMultiplier = 2,
	ApplyToModel = function(model: Model)
		local Particles = script:WaitForChild("Particles")
		local defaultScale = Vector3.new(5.565, 2.443, 2.823)

		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("BasePart") then
				local part = obj :: BasePart
				local originalColor = part.Color
				
			-- Calculate brightness/lightness of original color
			local brightness = (originalColor.R + originalColor.G + originalColor.B) / 3
			
			-- White/light colors become dark purple
			-- Darker colors become black, but very dark colors get minimum purple
			local purpleIntensity = brightness
			
			-- If color is very dark (close to black), give it a minimum purple value
			if brightness < 0.15 then
				purpleIntensity = 0.2 -- Minimum purple for very dark colors
			end
			
			-- Make 20% lighter
			-- purpleIntensity = math.min(purpleIntensity * 1.5, 1)
				
			-- Make it purple and black - dark purple has more red and blue, less green
			-- Using the base purple RGB(80, 42, 119) as reference
			local redComponent = purpleIntensity * (80/255)
			local greenComponent = purpleIntensity * (42/255)
			local blueComponent = purpleIntensity * (119/255)
				
				local newColor = Color3.new(redComponent, greenComponent, blueComponent)
				
				part.Color = newColor
			end

			if obj:GetAttribute("Eyes") and obj:IsA("BasePart") then
				local eye = obj :: BasePart
				eye.Color = Color3.fromRGB(255, 0, 0)
				eye.Material = Enum.Material.Neon
			end
		end

		local vfxBox = model:FindFirstChild("VFX")::BasePart
		if vfxBox and not vfxBox:GetAttribute("Added") then
			local scale = vfxBox.Size
			local scaleMultiplier = scale.Magnitude / defaultScale.Magnitude
			for _, particle in ipairs(Particles:GetChildren()) do
				local cloned = particle:Clone()

				if cloned:IsA("ParticleEmitter") and scaleMultiplier > 1.5 then
					scaleMultiplier = math.min(scaleMultiplier, 3)
					cloned.Rate = cloned.Rate * scaleMultiplier
				end

				cloned.Parent = vfxBox
			end
			vfxBox:SetAttribute("Added", true)
		end
	end
}