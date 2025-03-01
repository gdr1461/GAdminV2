local Command = {}
Command.Order = 16

Command.Name = "God"
Command.Alias = {"GodMode"}
Command.Description = "Makes player immortal."

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
	
	if self.Player.Players[player.UserId].Session.GodMode then
		return
	end
	
	self.Player.Players[player.UserId].Session.GodMode = true
	self.Player.Players[player.UserId].Session.MaxHealth = player.Character.Humanoid.MaxHealth
	
	local function Bind(Character)
		Character.Humanoid.MaxHealth = math.huge
		Character.Humanoid.Health = Character.Humanoid.MaxHealth
	end
	
	Bind(player.Character)
	self.Bind(player, "God", Bind)
end

function Command.Server:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
	}
end

return Command