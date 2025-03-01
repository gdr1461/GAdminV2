local Command = {}
Command.Order = 28

Command.Name = "Kick"
Command.Alias = {}
Command.Description = "Kicks specified player."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,
		
		Flags = {},--{"PlayerOther", "PlayerOnline", "RankLower"},
		Specifics = {},
	},
	
	{
		Name = "Reason",
		Types = {"string"},
		Rank = 2,

		Flags = {"Optional", "Infinite", "ToFilter"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1]
	local PlayerData = self.API.PlayerAPI:GetData(Caller)
	
	local Reason = Arguments[2] or PlayerData.Defaults.KickMessage
	player:Kick(Reason)
	self.Popup:New({
		Player = Caller,
		Type = "Notice",
		Text = `Player <font color="#ffbfaa">{player.Name}</font> has been kicked.`
	})
end

function Command.Server:Get(Services)
	return {
		API = Services.API,
		Popup = Services.Popup,
	}
end

return Command