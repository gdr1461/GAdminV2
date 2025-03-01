local Command = {}
Command.Order = TODO

Command.Name = "Test"
Command.Alias = {"T", "TestCommand"}
Command.Description = "N/A"

Command.Rank = 0
Command.Fluid = true
Command.Internal = true

Command.Arguments = {
	{
		Name = "Value1",
		Types = {"Object"},
		Rank = 5,

		Flags = {"Infinite"},
		Specifics = {
			Classes = {"StringValue"},
			Services = {"Workspace", "ReplicatedStorage"},
			Multiple = false,
			Properties = {
				
			}
		},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	print(Arguments[1])
end

return Command