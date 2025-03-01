local Command = {}
Command.Order = 44

Command.Name = "Shutdown"
Command.Alias = {}
Command.Description = "Shutdowns current server with specified reason if any."

Command.Rank = 4
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Reason",
		Types = {"string"},
		Rank = 3,
		
		Flags = {"Optional", "Infinite", "ToFilter"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local Reason = Arguments[1] or `By @{Caller.Name}`
	self.API:Shutdown(Reason)
end

function Command.Server:Get(Services)
	return {
		API = Services.API
	}
end

return Command