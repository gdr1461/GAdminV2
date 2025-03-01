local Command = {}
Command.Order = 45

Command.Name = "Chat"
Command.Alias = {}
Command.Description = "Open chat with player."

Command.Rank = 4
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
function Command.Client:Run(Caller, Arguments)
	local player = Arguments[1]
	_G.GAdmin.Framework.Chat:SetChat(player.UserId)
end

return Command