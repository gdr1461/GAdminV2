local Command = {}
Command.Order = 8

Command.Name = "Change"
Command.Alias = {"SetValue"}
Command.Description = "Changes value in the player leaderstats."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,

		Flags = {"Optional", "PlayerOnline"},
		Specifics = {},
	},
	
	{
		Name = "Stat",
		Types = {"Object"},
		Rank = 2,
		
		Flags = {},
		Specifics = {
			Services = function(Caller)
				return {Caller}
			end,
			
			Classes = {"IntValue", "NumberValue", "StringValue"},
			Multiple = false,

			Tags = {}
		}
	},
	
	{
		Name = "Value",
		Types = {"number", "string"},
		Rank = 2,

		Flags = {},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1] or Caller
	local Object = Arguments[2]
	local Value = Arguments[3]
	
	Object.Value = Value
end

return Command