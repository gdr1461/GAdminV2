local Command = {}
Command.Order = 29

Command.Name = "Bring"
Command.Alias = {"Br"}
Command.Description = "Teleports player to you."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,

		Flags = {"PlayerOnline"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1]
	local Position = Caller.Character:GetPivot() * CFrame.Angles(0, math.rad(180), 0)
	player.Character:PivotTo(Position)
end

return Command