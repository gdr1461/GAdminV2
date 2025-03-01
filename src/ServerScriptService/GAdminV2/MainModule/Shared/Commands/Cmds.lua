local Command = {}
Command.Order = 2

Command.Name = "Cmds"
Command.Alias = {"Commands", "Cmd"}
Command.Description = "Shows all of the commands that you can use."

Command.Rank = 0
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,
		
		Flags = {"Optional", "PlayerOnline", "PlayerClient"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Client:Run(Caller, Arguments)
	_G.GAdmin.Framework.Interface:SetLocation("Commands", 1, true)
end

return Command