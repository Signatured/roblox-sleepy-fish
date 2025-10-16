--!strict

return {
	DisplayName = "Spooky",
	Color = Color3.fromRGB(255, 128, 43),
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
				
				-- White/light colors become pure orange
				-- Darker colors become blackish orange, but very dark colors get minimum orange
				local orangeIntensity = brightness
				
				-- If color is very dark (close to black), give it a minimum orange value
				if brightness < 0.15 then
					orangeIntensity = 1 -- Minimum orange for very dark colors
				end
				
				-- Make it orange with high red and medium green components
				local redComponent = orangeIntensity  -- Keep full red
				local greenMultiplier = 0.6  -- Balanced green for light orange
				
				-- If original part is already super green, tone down the green by 40%
				if originalColor.G > 0.5 then
					greenMultiplier = greenMultiplier * 0.8  -- Reduce by 40%
				end
				
				local greenComponent = orangeIntensity * greenMultiplier
				local newColor = Color3.new(redComponent, greenComponent, 0)
				
				part.Color = newColor
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