--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

local module = {}

export type Save = {
	Variables: {[string]: any},
}

export type Packet = {
    PacketType: string,
	PlotId: number,
    Data: any
}

export type JoinPacket = {
    Owner: Player,
    CFrame: CFrame,
    SaveVariables: {[string]: any},
    SessionVariables: {[string]: any},
}

export type LeavePacket = {
    Owner: Player,
}

export type UpdatePacket = {
    Save: {{any}},
	Session: {{any}},
}

export type Fish = {
    UID: string,
	FishData: FishTypes.data_schema,
	FishId: string,
	LastClaimTime: number,
	CreateTime: number,
	OfflineEarnings: number,
}

function module.PedestalCost(index: number)
    return 1000 * index
end

return module