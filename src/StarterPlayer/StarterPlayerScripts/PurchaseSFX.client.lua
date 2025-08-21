--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Library.Client.Network)
local Audio = require(ReplicatedStorage.Library.Audio)

-- Play a local sound on successful Robux purchases
Network.Fired("PurchaseSuccess", function(productId: number, isProduct: boolean)
	Audio.Play("rbxassetid://88770892429695", script)
end)


