--!strict

export type AdminCommand = {
	DisplayName: string,
	CanTarget: boolean,
	OnExecute: (executor: Player?, targetPlayer: Player?) -> (boolean, (string | (() -> ()))?),
	Cooldown: number,
	Duration: number?, -- Optional: How long the command should run before calling finish function (in seconds)
	PreventGlobal: boolean?,
}

return {}
