--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local HumanoidProperty = require(Main.Shared.Services.Core.HumanoidProperty)

local Properties = HumanoidProperty:GetList()
local Property = ""
--==

local Command = {}
Command.Order = 33

Command.Name = "Logs"
Command.Alias = {}
Command.Description = "Shows command logs."

Command.Rank = 3
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"Optional", "PlayerOnline", "PlayerClient"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Client >>
function Command.Client:Run(Caller, Arguments)
	_G.GAdmin.Framework.Interface:Refresh({
		Place = "_Logs",
		Page = 1,
		MaxPages = 1,
		Arguments = {
			Type = "Logs",
		},
	})
end

return Command