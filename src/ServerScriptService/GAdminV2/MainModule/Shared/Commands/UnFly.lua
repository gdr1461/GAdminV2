--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
--==

local Command = {}
Command.Order = 13

Command.Name = "UnFly"
Command.Alias = {}
Command.Description = "Makes player unable fly."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"Optional", "PlayerOnline", "PlayerClient"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Client >>
function Command.Client:Run(Caller, Arguments)
	self.Window = self.Window or require(Main.Client.Services.Framework.Window)
	local PreviousWindow = self.Window.Find("Default", "Fly")

	if not PreviousWindow then
		return
	end

	local player = Arguments[1] or Caller
	PreviousWindow:Destroy()

	self.Fly:Disable(player)
	self.Bind(player, "Fly", nil)
end

function Command.Client:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
		Fly = Services.Core.Fly
	}
end

return Command