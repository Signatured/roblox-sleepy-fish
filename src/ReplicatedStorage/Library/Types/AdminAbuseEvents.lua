--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)

local module = {}

export type raw_dir = {
    DisplayName: string,
    Color: Color3,
    Icon: string,
    ServerFunctions: {
        OnStart: () -> (),
        Heartbeat: (delta: number, time: number) -> (),
        OnStop: () -> (),
    },
    ClientFunctions: {
        OnStart: () -> (),
        RenderStepped: (delta: number, time: number) -> (),
        OnStop: () -> (),
    }
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module




