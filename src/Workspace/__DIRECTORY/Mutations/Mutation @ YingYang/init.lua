--!strict

return {
	DisplayName = "Ying Yang",
	Color = Color3.fromRGB(255, 255, 255),
	MutationEarningsMultiplier = 2,
	ApplyToModel = function(model: Model)
		local Particles = script:WaitForChild("Particles")
		local defaultScale = Vector3.new(5.565, 2.443, 2.823)

		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("BasePart") then
				local part = obj :: BasePart
				local originalColor = part.Color
				
				-- Calculate brightness/lightness of original color (average of RGB)
				local brightness = (originalColor.R + originalColor.G + originalColor.B) / 3
				
				-- If more than 60% white, make it fully white, otherwise fully black
				local newColor
				if brightness > 0.6 then
					newColor = Color3.new(1, 1, 1) -- Fully white
				else
					newColor = Color3.new(0, 0, 0) -- Fully black
				end
				
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