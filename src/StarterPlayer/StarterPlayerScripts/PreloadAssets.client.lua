--!strict

local Audio = require(game.ReplicatedStorage.Library.Audio)

local preloadSounds = {
    "rbxassetid://139871930665325",
    "rbxassetid://107509119621196",
    "rbxassetid://83561525465892",
    "rbxassetid://85226925115980",
    "rbxassetid://117601096719800",
    "rbxassetid://85747710232715",
    "rbxassetid://124249358188422",
    "rbxassetid://76559039302900",
    "rbxassetid://88770892429695",
    "rbxassetid://95437214341584",
    "rbxassetid://132697192191142",
    "rbxassetid://123638861486059",
    "rbxassetid://94238694593476",
    "rbxassetid://95038957115197",
    "rbxassetid://80839855586532",
    "rbxassetid://110426600162491",
    "rbxassetid://133240422241361",
    "rbxassetid://91817413999532",
    "rbxassetid://126237239639574",
    "rbxassetid://137080714801874",
    "rbxassetid://6308606116" -- Jumpscare sound
}

Audio.PreloadSounds(preloadSounds)