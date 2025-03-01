local Command = {}
Command.Order = 5

Command.Name = "ServerMessage"
Command.Alias = {"SMessage", "SM"}
Command.Description = "Sends message to the current server."

Command.Rank = 2
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
	self.Remote:FireAll("SysMessage", {
		Type = "Center",
		From = `@{Caller.Name}`,
		Message = Message,
		Time = 10,
	})
end

function Command.Server:Get(Services)
	return {
		Remote = Services.Remote
	}
end

return Command