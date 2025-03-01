local Command = {}
Command.Order = 43

Command.Name = "GlobalMessage"
Command.Alias = {"GMessage", "GM"}
Command.Description = "Sends message to all of the servers."

Command.Rank = 4
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Message",
		Types = {"string"},
		Rank = 3,

		Flags = {"ToFilter", "Infinite"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local Message = Arguments[1]
	self.API:SendMessage("GA_SysMessage", {
		Caller.UserId,
		`@{Caller.Name}`,
		Message,
		10
	})
end

function Command.Server:Get(Services)
	return {
		API = Services.API
	}
end

return Command