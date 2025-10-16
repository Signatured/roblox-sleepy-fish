--!strict

return {
	DisplayName = "Galaxy",
	Color = Color3.fromRGB(114, 58, 255),
	MutationEarningsMultiplier = 2,
	ApplyToModel = function(model: Model)
		local Assets = game.ReplicatedStorage:WaitForChild("Assets")
		local defaultScale = Vector3.new(5.565, 2.443, 2.823)

		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("BasePart") then
				local part = obj :: BasePart
				local originalColor = part.Color
				
				-- Calculate brightness/lightness of original color
				local brightness = (originalColor.R + originalColor.G + originalColor.B) / 3
				
				-- White/light colors become pure purple
				-- Darker colors become blackish purple, but very dark colors get minimum purple
				local purpleIntensity = brightness
				
				-- If color is very dark (close to black), give it a minimum purple value
				if brightness < 0.15 then
					purpleIntensity = 0.15 -- Minimum purple for very dark colors
				end
				
				-- Make it more purple by reducing red component and keeping blue higher
				local redComponent = purpleIntensity * 0.8  -- 20% less red
				local blueComponent = purpleIntensity  -- Keep full blue
				local newColor = Color3.new(redComponent, 0, blueComponent)
				
				part.Color = newColor
			end
		end

		local vfxBox = model:FindFirstChild("VFX")::BasePart
		if vfxBox and not vfxBox:GetAttribute("Added") then
			local scale = vfxBox.Size
			local scaleMultiplier = scale.Magnitude / defaultScale.Magnitude
			local particles = Assets:FindFirstChild("Galaxy"):FindFirstChild("Particles")
			for _, particle in ipairs(particles:GetChildren()) do
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