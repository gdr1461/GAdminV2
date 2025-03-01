--[[
	Subscribes messages to given topics with specified callback.
]]

--== << Services >>
local Data = require(_G.GAdmin.Path.Server.Data)
local Remote = require(Data.Shared.Services.Remote)

local PlayerService = require(_G.GAdmin.Path.Server.Services.Player)
local FilterHandler = require(Data.Shared.Services.Core.Filter)
--==

local Load = {}
Load.Server = {}
Load.Client = {}

Load.Server.Messages = {
	{
		Topic = "GA_GlobalRankUpdate",
		Enums = {"Add", "Remove", "Change"},
		Callback = function(Data)
			Remote:FireAll("Interface", "TriggerDataMethod", "Ranks", "RefreshRanks", "ENUM.DEFAULT_ARGS")
			Remote:FireAll("Interface", "TriggerDataMethod", "_Rank", "RefreshUsers", "ENUM.DEFAULT_ARGS")
		end,
	},
	
	{
		Topic = "GA_GlobalBanlistUpdate",
		Enums = {},
		Callback = function(Data)
			Data.BanlistCache = PlayerService.API:GetBanlist("Formatted")
			Remote:FireAll("Interface", "TriggerDataMethod", "Ranks", "RefreshBanlist", "ENUM.DEFAULT_ARGS")
		end,
	},
	
	{
		Topic = "GA_PlayerBan",
		Enums = {},
		Callback = function(Data)
			local player = game.Players:GetPlayerByUserId(Data.UserId)
			if not player or not PlayerService.API:IsBanned(player) then
				return
			end
			
			PlayerService:__BanPrompt(player, Data.Ban)
		end,
	},
	
	{
		Topic = "GA_PlayerRank",
		Enums = {},
		Callback = function(Data)
			local player = game.Players:GetPlayerByUserId(Data[1])
			if not player then
				return
			end

			PlayerService:__RankPrompt(player, Data[2])
		end,
	},
	
	{
		Topic = "GA_SysMessage",
		Enums = {"Center", "Top", "Server"},
		Callback = function(Data)
			local Info = {
				Author = Data[1],
				From = Data[2],
				Message = Data[3],
				Time = Data[4]
			}
			
			Info.Message = FilterHandler:Filter(Info.Message, Info.Author)
			Remote:FireAll("SysMessage", Info)
		end,
	},
}

function Load.Server:Run()
	local API = self:Get(self.Services.API)
	for i, Message in ipairs(self.Messages) do
		API:SetMessage(Message.Topic, Message.Enums or {})
		API:ReceiveMessage(Message.Topic, Message.Callback)
	end
end

return Load