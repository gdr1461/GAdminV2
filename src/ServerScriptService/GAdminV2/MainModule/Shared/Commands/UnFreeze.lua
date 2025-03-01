local Command = {}
Command.Order = 11

Command.Name = "UnFreeze"
Command.Alias = {}
Command.Description = "Freezes player."

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
	self.Bind(player, "Freeze", nil)

	for i, Part in ipairs(player.Character:GetDescendants()) do
		if not Part:IsA("BasePart") then
			continue
		end

		Part.Anchored = false
	end
end

function Command.Server:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
	}
end

return Command