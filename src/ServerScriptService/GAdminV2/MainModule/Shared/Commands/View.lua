local Command = {}
Command.Order = 9

Command.Name = "View"
Command.Alias = {"Spectate"}
Command.Description = "Spectates specific player."

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

--== << cLIENT >>
function Command.Client:Run(Caller, Arguments)
	local player = Arguments[1] or Caller
	workspace.CurrentCamera.CameraSubject = player.Character
end

return Command