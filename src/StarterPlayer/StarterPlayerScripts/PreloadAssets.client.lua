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
    "rbxassetid://137080714801874",
    "rbxassetid://6308606116", -- Jumpscare sound
    -- "rbxassetid://100618183828369", -- Galaxy black hole loop
    -- "rbxassetid://131321022475059", -- Galaxy event start
    "rbxassetid://111689316568748", -- Galaxy vortex open/close
    "rbxassetid://73644741132942",
    "rbxassetid://78632974820364",
    "rbxassetid://130401084353873",
    "rbxassetid://81968496022483",
    "rbxassetid://70646733921269",
	"rbxassetid://138674084543064", -- lightning strike
	"rbxassetid://75263020536239", -- lightning strike
	"rbxassetid://78466157575717", -- lightning strike
    "rbxassetid://73851509377743", -- lightning storm start
    -- "rbxassetid://119969791895244", -- witch laugh

    "rbxassetid://125840884527985", -- haunted event start

    "rbxassetid://7511730566", -- knocking
    "rbxassetid://125209584906878", -- door open
    "rbxassetid://122398964277913", -- door close
    "rbxassetid://83210828687333", -- spawn haunted house fish

    -- Halloween crafting machine
    -- "rbxassetid://105973271745899", -- craft sound
    -- "rbxassetid://86764609074639", -- electricity loop
    -- "rbxassetid://108578182800070", -- successful craft sound

    "rbxassetid://138247726051800", -- Party Machine idle during event
    "rbxassetid://135729759317677", -- Party Machine power down
    "rbxassetid://116222140946445 ", -- Party Machine power up
    "rbxassetid://104359364272503", -- Party cannon shoot
    "rbxassetid://72111030447267", -- Party machine give fish
    "rbxassetid://96756442780379", -- Party Admin abuse event started
    "rbxassetid://119218265790569", -- Fish about to spawn sound

    "rbxassetid://139100592181941", -- YinYang event start
}

Audio.PreloadSounds(preloadSounds)