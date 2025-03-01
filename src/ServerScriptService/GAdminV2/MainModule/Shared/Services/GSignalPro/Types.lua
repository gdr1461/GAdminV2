export type GSignal = {
	Signals: {
		[string]: NewSignal
	},
	
	Create: (self: GSignal, Config: {
		Middlewares: {
			Entry: <CallArguments>(Context: NewSignal, ...CallArguments) -> boolean,
			Redact: (Context: NewSignal, CallArguments: {unknown?}) -> {unknown?},
		},
	}?) -> NewSignal,
	
	Get: (self: GSignal, Id: number?) -> NewSignal,
	GetAll: (self: GSignal, Name: string) -> {NewSignal},
}

export type NewSignal = {
	Debug: boolean?,
	State: States,
	Id: string,
	
	Ancestor: string,
	Connections: number,
	
	Freeze: (self: NewSignal) -> (),
	UnFreeze: (self: NewSignal) -> (),
	
	Fire: <CallArguments>(self: NewSignal, ...CallArguments) -> NewSignal,
	Connect: (self: NewSignal, Callback: <CallArguments>(...CallArguments) -> ()) -> NewConnection,
	
	Once: (self: NewSignal, Callback: <CallArguments>(...CallArguments) -> ()) -> NewConnection,
	Wait: <CallArguments>(self: NewSignal) -> ...CallArguments,
	
	DisconnectAll: (self: NewSignal) -> NewSignal,
	Destroy: (self: NewSignal) -> (),
}

export type NewConnection = {
	Disconnect: (self: NewConnection) -> (),
}

export type States = "Default" | "Frozen" | "Secured" | "Destroyed"

return {}