local Command = {}
Command.Order = 20

Command.Name = "ForceField"
Command.Alias = {"FF"}
Command.Description = "Gives forcefield to the player."

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
		if Character:FindFirstChild("ForceField") then
			Character.ForceField:Destroy()
		end

		local Field = Instance.new("ForceField")
		Field.Parent = Character
	end

	Bind(player.Character)
	self.Bind(player, "ForceField", Bind)
end

function Command.Server:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
	}
end

return Command