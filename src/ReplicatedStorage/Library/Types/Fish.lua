--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)
local RarityTypes = require(game.ReplicatedStorage.Game.Library.Types.Rarity)

local module = {}

export type raw_dir = {
    DisplayName: string,
    Icon: string,
    MutationIcons: {[string]: string}?,
    Rarity: RarityTypes.dir_schema,
    MoneyPerSecond: number,
    BaseUpgradeCost: number,
    BillboardOffset: number,
    RarityWeight: number,
    PedestalOffset: number?,
    IndexOffset: number?,
    IndexPositionOffset: Vector3?,
    IndexRotationOffset: Vector3?,
    BestFishMultiplier: number?,
    LuckyBlockId: string?,
}

export type fish_type = "Normal" | "Shiny" | "Gold" | "Rainbow"
export type fish_mutation_type = "Bloodfish" | "Galaxy"

export type data_schema = {
    UID: string,
    FishId: string,
    Type: fish_type,
    Mutation: fish_mutation_type?,
    Traits: {[string]: boolean}?,
    Shiny: boolean?,
    Level: number,
    CreateTime: number,
    BaseTime: number,
}

export type create_params = {
    FishId: string,
    Type: fish_type,
    Mutation: fish_mutation_type?,
    Shiny: boolean?,
    Level: number?,
}

export type swimming_fish_schema = {
    FishData: data_schema,
    SpawnTime: number,
    Carrier: Player?,
}

function module.MakeBloodfishModel(model: Model)
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

function module.MakeGalaxyModel(model: Model)
    local defaultScale = Vector3.new(5.565, 2.443, 2.823)
    local defaultZ = defaultScale.Z

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

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module