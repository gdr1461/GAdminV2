local Command = {}
Command.Order = 31

Command.Name = "To"
Command.Alias = {"Goto"}
Command.Description = "Teleports you to the player."

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
	local Position = player.Character:GetPivot() * CFrame.Angles(0, math.rad(180), 0)
	Caller.Character:PivotTo(Position)
end

return Command