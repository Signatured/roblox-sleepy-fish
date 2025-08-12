--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)

local module = {}

export type Save = {
	Variables: {[string]: any},
}

export type PacketType = "Join" | "Leave" | "Update"

export type Packet = {
    PacketType: PacketType,
	PlotId: number,
    Data: any
}

export type JoinPacket = {
    Owner: Player,
    CFrame: CFrame,
    Model: Model,
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

return module