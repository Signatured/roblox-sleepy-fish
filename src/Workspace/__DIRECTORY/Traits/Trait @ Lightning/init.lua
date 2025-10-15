--!strict

return {
    DisplayName = "Lightning",
    Color = Color3.fromRGB(100, 193, 255),
    Icon = "rbxassetid://103951511108485",
    TraitEarningsMultiplier = 1.5,
    ApplyToModel = function(model: Model)
        print(model)
    end
}