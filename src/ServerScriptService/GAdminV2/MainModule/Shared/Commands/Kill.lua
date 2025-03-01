local Command = {}
Command.Order = 18

Command.Name = "Kill"
Command.Alias = {}
Command.Description = "Kills specified player's character."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,

		Flags = {"Optional", "PlayerOnline"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1] or Caller
	player.Character:BreakJoints()
end

return Command