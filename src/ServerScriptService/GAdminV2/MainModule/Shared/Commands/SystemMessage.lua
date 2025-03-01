local Command = {}
Command.Order = 32

Command.Name = "SystemMessage"
Command.Alias = {"SMessage", "SM"}
Command.Description = "Sends message to the current server from custom user."

Command.Rank = 3
Command.Fluid = true

Command.Arguments = {
	{
		Name = "From",
		Types = {"string"},
		Rank = 3,

		Flags = {"ToFilter"},
		Specifics = {},
	},
	
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
	local From = Arguments[1]
	local Message = Arguments[2]
	
	self.Remote:FireAll("SysMessage", {
		Type = "Center",
		From = From,
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