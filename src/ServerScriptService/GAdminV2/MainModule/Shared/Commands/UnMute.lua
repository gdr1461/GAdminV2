local Command = {}
Command.Order = 41

Command.Name = "UnMute"
Command.Alias = {"UMute"}
Command.Description = "Unmutes specified player in the chat."

Command.Rank = 3
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"PlayerOnline"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1]
	self.Remote:Fire("Interface", player, "SetGuiCoreEnabled", "Chat", true)
end

function Command.Server:Get(Services)
	return {
		Remote = Services.Remote
	}
end

return Command