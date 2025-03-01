local Command = {}
Command.Order = 6

Command.Name = "Countdown"
Command.Alias = {"Count", "CD"}
Command.Description = "Count downs time."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Time",
		Types = {"number"},
		Rank = 2,

		Flags = {},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local Time = math.clamp(Arguments[1], 1, 99)
	for i = Time, 1, -1 do
		self.Remote:FireAll("SysMessage", {
			Type = "Center",
			From = `Server`,
			Message = i,
			Time = 1,
			SkipTween = i ~= Time,
		})
		
		task.wait()
	end
end

function Command.Server:Get(Services)
	return {
		Remote = Services.Remote
	}
end

return Command