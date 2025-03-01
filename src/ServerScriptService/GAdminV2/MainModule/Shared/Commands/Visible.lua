local Command = {}
Command.Order = 15

Command.Name = "Visible"
Command.Alias = {"Vis"}
Command.Description = "Makes player visible."

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
	for i, Part in ipairs(player.Character:GetDescendants()) do
		if (not Part:IsA("BasePart") and not Part:IsA("Decal")) or Part.Name == "HumanoidRootPart" then
			continue
		end

		Part.Transparency = 0
	end
end

return Command