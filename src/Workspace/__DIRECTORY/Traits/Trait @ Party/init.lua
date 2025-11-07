--!strict

return {
    DisplayName = "Party",
    Color = Color3.fromRGB(252, 255, 100),
    Icon = "rbxassetid://134009325983115",
    TraitEarningsMultiplier = 1.2,
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
        
        if vfxBox and not vfxBox:GetAttribute("PartyAdded") then
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

            local hatAttachment = vfxBox:FindFirstChild("Hat")::Attachment
            if hatAttachment then
                local hatModel = script:WaitForChild("PartyHat"):Clone()::Model
                hatModel:PivotTo(hatAttachment.WorldCFrame)

                local weld = Instance.new("WeldConstraint")
                weld.Part0 = model.PrimaryPart::BasePart
                weld.Part1 = hatModel.PrimaryPart::BasePart
                weld.Parent = model.PrimaryPart

                hatModel.Parent = model
            end

			vfxBox:SetAttribute("PartyAdded", true)
        end
    end
    
}