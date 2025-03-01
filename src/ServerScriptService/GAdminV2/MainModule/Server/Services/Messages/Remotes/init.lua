--== << Services >>
local TextService = game:GetService("TextService")
local Main = script:FindFirstAncestor("MainModule")
local Data = require(Main.Server.Data)

local API = require(Main.Server.Services.API)
local PlayerService = require(Main.Server.Services.Player)

local FilterHandler = require(Data.Shared.Services.Core.Filter)
local Restrictions = require(Data.Settings.Restrictions)

local SetRankTable = require(script.SetRank)
local SettingsHandler = require(script.SetSettings)
local SetChat = require(script.SetChat)

local Settings = require(Data.Settings.Main)
local AddonService = require(Data.Shared.Services.Addons)
local CodeService = require(Main.Server.Services.Code)

local RankService = require(Data.Shared.Services.Rank)
local RExecutor = RankService:Find(Restrictions.Server.Executor)

local RChangeRanks = RankService:Find(Restrictions.Ranks.ChangeRanks)
local RAPIBan = RankService:Find(Restrictions.APIBan)
local RChangeBanlist = {
	Server = RankService:Find(Restrictions.Ranks.ChangeBanlistServer),
	Global = RankService:Find(Restrictions.Ranks.ChangeBanlistGlobal)
}

--==

return {
	GetDefault = function(player)
		local Addons = {}
		for Addon, Info in pairs(AddonService.Loaded) do
			table.insert(Addons, {
				Name = Info.Config.Name,
				Description = Info.Config.Description,
				Author = Info.Config.Author,
				Version = Info.Config.Version,
				Tag = Info.Config.Tag,
				Parameters = AddonService:GetParameters(Addon),
			})
		end
		
		return {
			Version = _G.GAdmin.Module.__version,
			Icon = Data.Icon,
			VersionLog = Data.VersionLog,
			AssetId = Data.AssetId,
			Donations = Data.Donations,
			CreatorId = API:GetOwnerId(),
			Addons = Addons,
		}
	end,

	GetVersion = function(player)
		return _G.GAdmin.Module.__version
	end,

	GetIcon = function(player)
		return Data.Icon
	end,

	GetInfo = function(player)
		if not PlayerService.Players[player.UserId] then
			local Start = tick()
			local Warned = false

			repeat
				if tick() - Start >= 15 then
					warn(`[GAdmin Remotes]: GetInfo :: Cancelling request for {player.Name} data.`)
					return
				end

				if tick() - Start >= 5 and not Warned then
					Warned = true
					warn(`[GAdmin Remotes]: GetInfo :: Unable to get {player.Name}'s player data for over 5 seconds, retrying`)
				end

				task.wait()
			until PlayerService.Players[player.UserId]
		end

		return PlayerService.Players[player.UserId].Data
	end,

	GetRanks = function(player)
		return Data.RankCache
	end,

	SetPrefix = function(player, Prefix)
		if type(Prefix) ~= "string" then
			warn(`[GAdmin Remotes]: {player.Name} SetPrefix :: Prefix must be a type of string.`)
			return
		end

		API:SetPrefix(player, Prefix)
	end,

	GetPlayers = function(player)
		return PlayerService.Players
	end,

	SetRank = function(player, Action, RankData, Locally)
		if not SetRankTable[Action] then
			warn(`[GAdmin Messages]: SetRank :: Action '{Action}' is invalid.`)
			return {-1}
		end

		return SetRankTable[Action](player, RankData, Locally)
	end,

	GetBanlist = function(player)
		return Data.BanlistCache
	end,

	Ban = function(player, UserId, UserOptions)
		if not tonumber(UserId) or UserId ~= UserId then
			return false, "UserId must be specified."
		end

		if player.UserId == UserId then
			return false, "You can't ban yourself."
		end

		if not UserOptions then
			return false, "UserOptions must be specified."
		end

		if type(UserOptions) ~= "table" then
			return false, "UserOptions must be a table."
		end

		if UserOptions.API ~= nil and type(UserOptions.API) ~= "boolean" then
			return false, "'API' Option must be a boolean."
		end

		if UserOptions.Locally ~= nil and type(UserOptions.Locally) ~= "boolean" then
			return false, "'Locally' Option must be a boolean."
		end

		if UserOptions.ApplyToUniverse ~= nil and type(UserOptions.ApplyToUniverse) ~= "boolean" then
			return false, "'ApplyToUniverse' Option must be a boolean."
		end

		if not table.find({"string", "number"}, type(UserOptions.Time)) or UserOptions.Time ~= UserOptions.Time then
			return false, "'Time' Option must be a number."
		end

		if UserOptions.Reason ~= nil and (type(UserOptions.Reason) ~= "string" or not utf8.len(UserOptions.Reason)) then
			return false, "'Reason' Option must be a string."
		end

		if UserOptions.PrivateReason ~= nil and (type(UserOptions.PrivateReason) ~= "string" or not utf8.len(UserOptions.PrivateReason)) then
			return false, "PrivateReason Option must be a string."
		end

		local Type = UserOptions.Locally and "Server" or "Global"
		local Restriction = RChangeBanlist[Type]
		
		local PlayerRank = API:GetRank(player)
		local UserRank = API:GetRank(UserId)
		
		local Success, Name = pcall(function()
			return game.Players:GetNameFromUserIdAsync(UserId)
		end)
		
		if not Success then
			return false, "User does not exist."
		end

		if PlayerRank.Rank < Restriction.Rank then
			return false, `Rank higher than '<font color="#ffbfaa">{Restriction.Name}</font>' required.`
		end
		
		if UserRank.Rank >= PlayerRank.Rank then
			return false, `Rank of <font color="#ffbfaa">{Name}</font> is higher than yours. (<font color="#ffbfaa">{UserRank.Name}</font>)`
		end
		
		if UserOptions.API and PlayerRank.Rank < RAPIBan.Rank then
			return false, `Rank higher than '<font color="#ffbfaa">{RAPIBan.Name}</font>' required to API ban someone.`
		end

		local PlayerData = API.PlayerAPI:GetData(player)
		UserOptions = UserOptions or {}

		UserOptions.Reason = UserOptions.Reason or PlayerData.Defaults.BanMessage
		UserOptions.PrivateReason = UserOptions.PrivateReason or "None."
		UserOptions.Time = UserOptions.Time or 60

		local Options = {}
		Options.Moderator = player.UserId
		Options.Locally = Type == "Server"

		Options.API = UserOptions.API
		Options.ApplyToUniverse = UserOptions.ApplyToUniverse

		Options.Reason = FilterHandler:Filter(UserOptions.Reason, player.UserId)
		Options.PrivateReason = FilterHandler:Filter(UserOptions.PrivateReason, player.UserId)
		Options.Time = UserOptions.Time

		return API:Ban(UserId, Options)
	end,

	Unban = function(player, UserId, Type)
		Type = Type or "Global"
		if not table.find({"Server", "Global"}, Type) then
			return false, `Unknown unban type '{Type}'.`
		end

		local PlayerRank = API:GetRank(player)
		local Restriction = RChangeBanlist[Type]

		if PlayerRank.Rank < Restriction.Rank then
			return false, `Rank higher than '<font color="#ffbfaa">{Restriction.Name}</font>' required.`
		end

		local Success, Response = API:UnBan(tonumber(UserId), Type)
		return Success, Response
	end,

	RunCommand = function(player, Message)
		local Success = API.PlayerAPI:OnMessage(player, Message)
		return Success
	end,

	SetSettings = function(player, Settings, Custom)
		if Custom then
			local Success, Response = SettingsHandler.SetCustom(player, PlayerService.Players[player.UserId].Data, Custom)
			if not Success then
				return Success, Response
			end

			PlayerService.Players[player.UserId].Data = Response
		end

		local Success, Response = SettingsHandler.SetSettings(player, PlayerService.Players[player.UserId].Data.Settings, Settings)
		if Success then
			PlayerService.Players[player.UserId].Data.Settings = Settings
		end

		return Success, Response
	end,

	RunCode = function(player, Action, Argument, ...)
		local RankData = API:GetRank(player)
		if not Settings.ExecutorEnabled then
			return false, "Executor is disabled."
		end

		if RankData.Rank < RExecutor.Rank then
			return false, `Rank '<font color="#ffbfaa">{RExecutor.Name}</font>+' required.`
		end

		if not Data.MainExecutor[Action] then
			return false, "An unknown error occurred."
		end

		return true, Data.MainExecutor[Action](Data.MainExecutor, Argument, player, ...)
	end,

	Filter = function(player, Message)
		return FilterHandler:Filter(Message, player.UserId)
	end,

	GetPlayer = function(player, UserId)
		if not UserId or type(UserId) ~= "number" or not PlayerService.Players[UserId] then
			return
		end

		return PlayerService.Players[UserId]
	end,

	AddUser = function(player, RankLike, UserId, Locally)
		local PlayerRank = API:GetRank(player)
		if not PlayerRank or PlayerRank.Rank < RChangeRanks.Rank then
			return false, `Rank higher than '<font color="#ffbfaa">{RChangeRanks.Name}</font>' required.`
		end

		local RankData = RankService:Find(RankLike)
		if not RankData then
			return false, "Rank is not valid."
		end

		if RankData.Rank >= 5 then
			return false, "Can not change rank with owner permissions."
		end

		if RankData.Rank >= PlayerRank.Rank then
			return false, `Rank higher than '<font color="#ffbfaa">{RankData.Name}</font>' required.`
		end

		local Success, Name = pcall(function()
			return game.Players:GetNameFromUserIdAsync(UserId)
		end)

		if not Success then
			return false, "UserId is not valid."
		end

		UserId = tonumber(UserId)
		local UserRank = RankService:FindUser(UserId)

		if UserRank.Rank == RankData.Rank then
			return false, `User '<font color="#ffbfaa">{Name}</font>' already owns this rank.`
		end

		if UserRank.Rank >= PlayerRank.Rank then
			return false, `Rank of <font color="#ffbfaa">{Name}</font> is higher than yours. (<font color="#ffbfaa">{UserRank.Name}</font>)`
		end

		RankService:AddUser(RankLike, UserId, Locally)
		API:SendMessage("GA_GlobalRankUpdate", {"Change"})

		return true 
	end,

	RemoveUser = function(player, UserId, Locally)
		local PlayerRank = API:GetRank(player)
		if not PlayerRank or PlayerRank.Rank < RChangeRanks.Rank then
			return false, `Rank higher than '<font color="#ffbfaa">{RChangeRanks.Name}</font>' required.`
		end

		local Success, Name = pcall(function()
			return game.Players:GetNameFromUserIdAsync(UserId)
		end)

		if not Success then
			return false, "UserId is not valid."
		end

		UserId = tonumber(UserId)
		local UserRank = RankService:FindUser(UserId)

		if UserRank.Rank >= PlayerRank.Rank then
			return false, `Rank of <font color="#ffbfaa">{Name}</font> is higher than yours. (<font color="#ffbfaa">{UserRank.Name}</font>)`
		end

		RankService:RemoveUser(UserId, Locally)
		API:SendMessage("GA_GlobalRankUpdate", {"Change"})

		return true
	end,

	GetLogs = function(player, Type)
		if not table.find({"ChatLogs", "Logs"}, Type) then
			return
		end

		local Logs = Type == "ChatLogs" and Data.ChatLogs or Data.Logs
		return Logs
	end,
	
	Chat = function(player, Action, ...)
		if not SetChat[Action] then
			return
		end
		
		SetChat[Action](SetChat, player, ...)
	end,
	
	Code = function(player, Action, Id, Code)
		if Action == "Load" then
			return CodeService:Load(player, Id, Code)
		end
		
		return CodeService:Save(player, Id, Code)
	end,
}