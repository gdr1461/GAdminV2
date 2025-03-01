local Command = {}
Command.Order = 10

Command.Name = "Freeze"
Command.Alias = {}
Command.Description = "Unfreezes player."

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
	local function Bind(Character)
		for i, Part in ipairs(Character:GetDescendants()) do
			if not Part:IsA("BasePart") then
				continue
			end

			Part.Anchored = true
		end
	end

	Bind(player.Character)
	self.Bind(player, "Freeze", Bind)
end

function Command.Server:Get(Services)
	return {
		Bind = Services.Core.CharacterBind
	}
end

return Command