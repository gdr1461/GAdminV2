local Command = {}
Command.Order = 46

Command.Name = "OpenChat"
Command.Alias = {}
Command.Description = "Open chat where you left it."

Command.Rank = 4
Command.Fluid = true

Command.Arguments = {}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Client:Run(Caller, Arguments)
	_G.GAdmin.Framework.Chat:SetVisible(true)
end

return Command