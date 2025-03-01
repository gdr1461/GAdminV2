local Command = {}
Command.Order = 21

Command.Name = "UnForceField"
Command.Alias = {"UnFF"}
Command.Description = "Removes forcefield from the player."

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
	self.Bind(player, "ForceField", nil)
	
	if not player.Character:FindFirstChild("ForceField") then
		return
	end
	
	player.Character.ForceField:Destroy()
end

function Command.Server:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
	}
end

return Command