local Command = {}
Command.Order = 26

Command.Name = "Jump"
Command.Alias = {}
Command.Description = "Forces player to jump."

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
	player.Character.Humanoid.Jump = true
end

return Command