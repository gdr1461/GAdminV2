local Command = {}
Command.Order = 23

Command.Name = "Give"
Command.Alias = {"Tool", "GiveTool"}
Command.Description = "Gives tool to the player."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"Optional", "PlayerOnline"},
		Specifics = {},
	},
	
	{
		Name = "Tool",
		Types = {"Object"},
		Rank = 2,
		
		Flags = {"Infinite"},
		Specifics = {
			Services = {"Workspace", "ReplicatedStorage", "ServerStorage", "StarterPack"},
			Classes = {"Tool"},
			Multiple = false,
			
			Tags = {
				{
					Alias = {"all", "every"},
					Call = function(Objects, Specifics)
						return Objects
					end,
				}
			}
		},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1] or Caller
	local Tool = Arguments[2]
	
	local Copy = Tool:Clone()
	Copy.Parent = player.Backpack
end

return Command