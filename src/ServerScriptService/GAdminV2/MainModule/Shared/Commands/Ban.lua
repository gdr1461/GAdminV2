--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local RankService = require(Main.Shared.Services.Rank)

local Restrictions = require(Main.Settings.Restrictions)
local RChangeBanlist = RankService:Find(Restrictions.Ranks.ChangeBanlistGlobal)
--==

local Command = {}
Command.Order = 34

Command.Name = "Ban"
Command.Alias = {"GlobalBan", "GBan"}
Command.Description = "Bans specified player."

Command.Rank = RChangeBanlist.Rank
Command.Fluid = true

Command.Arguments = {
	
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Client:Run(Caller, Arguments)
	_G.GAdmin.Framework.Interface:Refresh({
		Place = "_Ban",
		Page = 1,
		MaxPages = 1,
		Arguments = {
			Type = "Global",
		},
	})
end

return Command