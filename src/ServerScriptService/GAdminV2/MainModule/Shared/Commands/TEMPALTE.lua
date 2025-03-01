local Command = {}
Command.Order = -1

Command.Name = "Test"
Command.Alias = {"TestCommand"}
Command.Description = "Test command."

Command.Rank = 0
Command.Fluid = true

Command.Arguments = {
	{ -- Argument which returns player that must be online. Not optional.
		Name = "Player",
		Type = {"Player"},
		Rank = 0,
		
		Flags = {"PlayerOnline"},
		Specifics = {},
	},
	
	{ -- Argument which returns either number or string. Not optional.
		Name = "Number",
		Type = {"number", "string"},
		Rank = 0,
		
		Flags = {},
		Specifics = {},
	},
	
	{ -- Argument which returns object that is class of ModuleScript. Optional, must have rank mod or higher. 
		Name = "GAdmin",
		Type = {"Object"},
		Rank = 2,
		
		Flags = {"Optional"},
		Specifics = {
			IsClass = {"ModuleScript"},
		},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	self.Popup:New({
		Type = "Notice",
		Text = Arguments[2],
		Player = Caller
	})
end

--[[
	Store dependencies here.
	Once called, will transfer all of the keys from returned table into Command.Server.
	
	@Example:
		In :Get() method:
			return {Popup = Services.Popup}
			
		In :Run() method:
			self.Popup:New(...)
		
]]
function Command.Server:Get(Services)
	return {
		Popup = Services.Popup
	}
end

--== << Client >>
function Command.Client:Run(Caller, Arguments)
	self.Popup:New({
		Type = "Notice",
		Text = Arguments[2] + 2,
		Player = Caller
	})
end

--[[
	Store dependencies here.
	Once called, will transfer all of the keys from returned table into Command.Client.
	
	@Example:
		In :Get() method:
			return {Popup = Services.Popup}
			
		In :Run() method:
			self.Popup:New(...)
		
]]
function Command.Client:Get(Services)
	return {
		Popup = Services.Popup
	}
end

return Command