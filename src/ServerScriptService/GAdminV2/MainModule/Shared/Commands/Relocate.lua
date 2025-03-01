local Command = {}
Command.Order = 1

Command.Name = "Relocate"
Command.Alias = {"Reloc"}
Command.Description = "Relocates GAdmin Panel to the starting point."

Command.Rank = 0
Command.Fluid = true

Command.Arguments = {
	
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Caller
	self.Remote:Fire("Interface", player, "Relocate")
end

function Command.Server:Get(Services)
	return {
		Remote = Services.Remote
	}
end

return Command