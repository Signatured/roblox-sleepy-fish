--!strict

return {
    DisplayName = "Lightning",
    Color = Color3.fromRGB(100, 193, 255),
    Icon = "rbxassetid://88095773014449",
    TraitEarningsMultiplier = 1.5,
    ApplyToModel = function(model: Model)
        local defaultScale = Vector3.new(5.565, 2.443, 2.823)
        local particles = script:WaitForChild("Particles"):Clone()
        local vfxBox = model:FindFirstChild("VFX")::BasePart

        local function scaleParticlesResursively(obj: Instance, scaleMultiplier: number)
            if obj:IsA("ParticleEmitter") and scaleMultiplier > 1.5 then
                scaleMultiplier = math.min(scaleMultiplier, 3)
                obj.Rate = obj.Rate * scaleMultiplier
            end
            for _, child in obj:GetChildren() do
                scaleParticlesResursively(child, scaleMultiplier)
            end
        end
        
        if vfxBox and not vfxBox:GetAttribute("LightningAdded") then
            local scale = vfxBox.Size
			local scaleMultiplier = scale.Magnitude / defaultScale.Magnitude
            local cloned: {Instance} = {}
            for _, obj in ipairs(particles:GetChildren()) do
                local clonedObj = obj:Clone()
                clonedObj.Parent = vfxBox
                table.insert(cloned, clonedObj)
            end
			for _, obj in ipairs(cloned) do
				scaleParticlesResursively(obj, scaleMultiplier)
			end
			vfxBox:SetAttribute("LightningAdded", true)
        end
    end
    
}