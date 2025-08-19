--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local Network = require(ReplicatedStorage.Library.Client.Network)

local localPlayer = Players.LocalPlayer

local function findFirstButton(parent: Instance): GuiButton?
    if parent:IsA("GuiButton") then
        return parent
    end
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("GuiButton") then
            return child
        end
    end
    return nil
end

local function setup()
    local dropGui = GUI.DropButton()
    local button = findFirstButton(dropGui)

    local function isCarrying(): boolean
        local carryingId = localPlayer:GetAttribute("CarryingFishId")
        return carryingId ~= nil
    end

    local function updateVisibility()
        local enabled = isCarrying()
        if button then
            button.Visible = enabled
            -- Also ensure parent GUI is enabled if present
            if dropGui and dropGui:IsA("ScreenGui") then
                (dropGui :: ScreenGui).Enabled = true
            end
        else
            if dropGui and dropGui:IsA("ScreenGui") then
                (dropGui :: ScreenGui).Enabled = enabled
            end
        end
    end

    if button then
        button.Activated:Connect(function()
            if isCarrying() then
                Network.Fire("DropFish")
            end
        end)
    end

    updateVisibility()
    localPlayer:GetAttributeChangedSignal("CarryingFishId"):Connect(updateVisibility)
end

setup()


