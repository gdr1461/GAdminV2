local Command = {}
Command.Order = 22

Command.Name = "Respawn"
Command.Alias = {"Re", "R"}
Command.Description = "Forces player to respawn."

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
	local Position = player.Character:GetPivot()
	
	player:LoadCharacter()
	player.Character:PivotTo(Position)
end

return Command