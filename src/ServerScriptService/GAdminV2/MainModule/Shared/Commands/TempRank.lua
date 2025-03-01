--== << Services >>
local Players = game:GetService("Players")
--==

local Command = {}
Command.Order = 37

Command.Name = "TempRank"
Command.Alias = {"ServerRank", "TR"}
Command.Description = "Sets specified player's rank on this server."

Command.Rank = 3
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"PlayerOnline", "PlayerOther", "RankLower"},
		Specifics = {},
	},
	
	{
		Name = "Rank",
		Types = {"Rank"},
		Rank = 3,

		Flags = {"RankLower"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1]
	local Rank = Arguments[2]

	local PlayerName = typeof(player) == "Instance" and player.Name or nil
	local UserId = typeof(player) == "Instance" and player.UserId or tonumber(player)

	if not PlayerName then
		local Success, Response = pcall(function()
			return Players:GetNameFromUserIdAsync(tonumber(player))
		end)

		if not Success then
			warn(`[GAdmin Commands]: Rank :: API ERROR :: {Response}`)
			self.Popup:New({
				Player = Caller,
				Type = "Error",
				Text = `API ERROR :: '<font color="#ffbfaa">{Response}</font>'`
			})

			return
		end

		PlayerName = Response
	end

	self.API:SetRank(player, Rank.Rank, true)
	self.Popup:New({
		Player = Caller,
		Type = "Notice",
		Text = `Rank of <font color="#ffbfaa">{PlayerName}</font> has been successfully set to <font color="#ffbfaa">{Rank.Name}</font>. (<font color="#ffbfaa">{Rank.Rank}</font>)`
	})
	
	self.Remote:FireAll("Interface", "TriggerDataMethod", "Ranks", "RefreshRanks", "ENUM.DEFAULT_ARGS")
	if typeof(player) == "Instance" then
		self.API.PlayerAPI:__RankPrompt(player, Rank.Rank)
	end
end

function Command.Server:Get(Services)
	return {
		Popup = Services.Popup,
		API = Services.API,
		Remove = Services.Remote,
	}
end

return Command