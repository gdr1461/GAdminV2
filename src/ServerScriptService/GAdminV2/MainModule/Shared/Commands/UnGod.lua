local Command = {}
Command.Order = 17

Command.Name = "UnGod"
Command.Alias = {"UnGodMode"}
Command.Description = "Makes player mortal."

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
	self.Player = self.Player or require(_G.GAdmin.Path.Server.Services.Player)
	local player = Arguments[1] or Caller
	
	if not self.Player.Players[player.UserId].Session.GodMode then
		return
	end
	
	self.Player.Players[player.UserId].Session.GodMode = false
	self.Bind(player, "God", nil)
	
	player.Character.Humanoid.MaxHealth = self.Player.Players[player.UserId].Session.MaxHealth or 100
	player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
end

function Command.Server:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
	}
end

return Command