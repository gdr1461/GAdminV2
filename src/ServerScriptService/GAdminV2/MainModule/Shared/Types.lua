--[[
	
	This module stores all of GAdmin's types.
	In case you need a reference, you can go here and search what you need.
	
	!TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! 
	!TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! 
	!TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! !TODO! 
	
]]--

export type GAdminV2 = {
	Load: (self: GAdminV2) -> (),
}

--== << Services >>
export type ConsoleService = {
	List: (self: ConsoleService, Title: string?, AutoPrint: boolean?) -> ConsoleList,
}

export type ParseService = {
	Call: (self: ParseService, Branch: CommandBranch) -> unknown,
	Parse: (self: ParseService, Caller: Player, Message: string) -> {
		CommandBranch
	},
	
	Transform: (self: ParseService, Branch: CommandBranch, Arguments: {string}) -> {unknown},
}

export type CommandsService = {
	Commands: {
		[string]: CommandPrototype
	},
	
	Reload: (self: CommandsService) -> (),
	GetList: (self: CommandsService) -> {CommandPrototype},
	Find: (self: CommandsService, Command: string) -> CommandPrototype
}

export type RankService = {
	Find: (self: RankService, NameOrPlace: string | number) -> RankPrototype
}

export type DataStoreService = {
	Key: (self: DataStoreService, Store: Stores, Key: string) -> (boolean, unknown),
	Save: (self: DataStoreService, Store: Stores, Key: string, Data: unknown) -> boolean,
}

export type PlayerService = {
	Players: {PlayerPrototype},
	Load: (self: PlayerService) -> (),
	
	Bind: (self: PlayerService, player: Player) -> (),
	UnBind: (self: PlayerService, player: Player) -> (),
}

export type Framework = {}

--== << APIs >>
export type ServerAPI = {
	GetPrefix: (self: ServerAPI, Player: Player) -> string,
}

--== << Other >>
export type Arguments = "number" | "string" | "boolean" | "Player" | "Object" | "Rank"
export type ArgumentFlags = "PlayerOnline" | "PlayerOffline" | "ToFilter" | "Optional" | "RankLower" | "RankHigher" | "Infinite"
export type Stores = "System" | "Player"

export type Argument = {
	Name: string,
	Type: {Arguments},
	Rank: number | string,
	
	Flags: {ArgumentFlags},
	Specific: {
		IsClass: {Instances},
		InRange: {
			Min: number,
			Max: number,
		}
	}
}

export type ConsoleList = {
	List: {string},
	AutoPrint: boolean,
	
	Header: string,
	Prefix: string?,
	
	Add: (self: ConsoleList, String: string) -> (),
	End: (self: ConsoleList) -> (),
	Destroy: (self: ConsoleList) -> (),
}

export type CommandPrototype = {
	Order: number, -- Order of the command in list.
	Rank: number, -- Rank requirment for player to have permission to use this command.

	Name: string, -- Name of the command.
	Alias: {string}, -- Other names of the command.
	Description: string, -- Description of command.

	Fluid: boolean, -- Makes command updatable and not case sensitive.
	Arguments: {Argument}, -- List of arguments types command needs.
	
	Server: {
		Run: (self: CommandPrototype, Caller: Player, Arguments: {unknown}) -> (), -- Run command on the server.
		Update: (self: CommandPrototype) -> (), -- Updates command on the server.
	},
	
	Client: {
		Run: (self: CommandPrototype, Caller: Player, Arguments: {unknown}) -> (), -- Run command on the client.
	}
}

export type CommandBranch = {
	Caller: Player,
	Command: string,

	RawArguments: {string},
	Arguments: {unknown},
}

export type RankPrototype = {
	Name: string,
	Place: number,
	Players: {string | number}
}

export type PlayerPrototype = {
	Data: PlayerDataStore,
	Session: {
		[string]: unknown
	}
}

export type BanPrototype = {
	UserId: number,
	ModUserId: number,
	
	On: number,
	Until: number,
}

export type RankExpirationPrototype = {
	PreviousRank: number,
	On: number,
	Until: number,
}

export type PlayerSessionPrototype = {
	Listeners: {
		[string]: RBXScriptConnection,
	},
}

export type LogPrototype = {
	UserId: number,
	Time: number,
	Message: string,
}

--== << DataStores >>
export type PlayerDataStore = {
	Prefix: string,
	Rank: number,
	RankExpiration: RankExpirationPrototype | nil,
	Defaults: PlayerDefaults,
}

export type SystemDataStore = {
	Bans: {BanPrototype}
}

return {}