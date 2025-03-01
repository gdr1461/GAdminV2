local Command = {}
Command.Order = 30

Command.Name = "Teleport"
Command.Alias = {"Tp"}
Command.Description = "Teleports player1 to player 2."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player1",
		Types = {"Player"},
		Rank = 2,

		Flags = {"PlayerOnline"},
		Specifics = {},
	},
	
	{
		Name = "Player2",
		Types = {"Player"},
		Rank = 2,

		Flags = {"Optional", "PlayerOnline"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player1 = Arguments[1]
	local player2 = Arguments[2] or Caller
	
	local Position = player2.Character:GetPivot() * CFrame.Angles(0, math.rad(180), 0)
	player1.Character:PivotTo(Position)
end

return Command