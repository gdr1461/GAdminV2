--[=[
	@class PlayerAPI
	@server
	@tag API
	Handles player-based actions.
	
	Location: `GAdminV2.MainModule.Server.Services.PlayerAPI`
]=]

--[=[
	@interface PlayerAPI
	@within PlayerAPI
	@field __type string
	@field Players {[number]: PlayerData}
	@field API ServerAPI
	@field __RankPrompt (Player: Player, Rank: RankLike) -> nil
	@field __BanPrompt (Player: Player, BanData: BanOptions) -> nil
	@field Load (API: ServerAPI) -> nil
	@field GetUserId (PlayerLike: UserLike) -> number
	@field GetData (PlayerLike: UserLike) -> PlayerData
	@field SetData (PlayerLike: UserLike, Key: string, Value: any) -> boolean | nil
	@field OnMessage (player: Player, Message: string, Options: OnMessageOptions) -> PlayerData
	@field Bind (player: Player) -> nil
	@field UnBind (player: Player) -> nil
]=]

--[=[
	@interface PlayerData
	@field Data {[string]: any} -- Session player data.
	@field Session {[string]: any} -- Savable player session data.
	@within PlayerAPI
]=]

--[=[
	@interface OnMessageOptions
	@field NoLimit boolean -- Disables command limit.
	@field NoLog boolean -- Disables logging.
	@within PlayerAPI
]=]

--[=[
	@type UserLike number | string | Player
	@within PlayerAPI
]=]

--== << Services >>
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local TextService = game:GetService("TextService")
local Main = script:FindFirstAncestor("MainModule")

local Data = require(Main.Server.Data)
local Parser

local DataStore = require(Main.Server.Services.DataStore)
local Popup = require(Data.Shared.Services.Popup)
local Configuration = require(Data.Settings.Main)

local SettingHandler = require(script.Settings)
local PlayerSettings = require(Data.Settings.PlayerData)
local Restrictions = require(Data.Settings.Restrictions)
--==

local Proxy = newproxy(true)
local Player = getmetatable(Proxy)

Player.__type = "GAdmin Player"
Player.__metatable = "[GAdmin Player]: Metatable methods are restricted."

--[=[
	Player datas.
	@prop Players {[number]: PlayerData}
	@within PlayerAPI
]=]
Player.Players = {}
SettingHandler.PlayerAPI = Proxy

function Player:__tostring()
	return self.__type
end

function Player:__index(Key)
	return Player[Key]
end

function Player:__newindex(Key, Value)
	Player[Key] = Value
end

--[=[
	Sends new popup to a player from given rank..

	@private
	@param Player Player
	@param Rank RankLike
	@within PlayerAPI
	@return nil
]=]
function Player:__RankPrompt(Player, Rank)
	local RankData = self.API.RankService:Find(Rank)
	if not RankData then
		return
	end
	
	Popup:New({
		Player = Player,
		Type = "Notice",
		Text = `Your rank has been set to <font color="#ffbfaa">{RankData.Name}</font>. (<font color="#ffbfaa">{RankData.Rank}</font>)`
	})
end

--[=[
	Kicks player with given prompt.

	@private
	@param Player Player
	@param BanData BanOptions
	@within PlayerAPI
	@return nil
]=]
function Player:__BanPrompt(Player, BanData)
	BanData = _G.GAdmin.__GetBanData(BanData)
	if BanData.API then
		return
	end

	local Success, Moderator = pcall(function()
		return Players:GetNameFromUserIdAsync(tonumber(BanData.Moderator))
	end)

	Moderator = Success and Moderator or "System"
	local Time = DateTime.fromUnixTimestamp(tonumber(BanData.Time)):FormatLocalTime("HH:mm:ss LL", "en-us")

	Player:Kick(`Moderator {Moderator} banned you{BanData.Locally and " from this server" or ""} until {Time}. Reason: '{BanData.Reason}'`)
end

--[=[
	Loads Player API.

	@private
	@param API ServerAPI
	@within PlayerAPI
	@return nil
]=]
function Player:Load(API)
	self.API = API
	Data.ConnectionBase.PlayerAdded = Players.PlayerAdded:Connect(function(player)
		self:Bind(player)
		player.Chatted:Connect(function(...)
			self:OnMessage(player, ...)
		end)
	end)
	
	Data.ConnectionBase.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
		self:UnBind(player)
	end)
	
	game:BindToClose(function()
		for i, player in ipairs(Players:GetPlayers()) do
			coroutine.wrap(self.UnBind, self, player)
		end
	end)
end

--[=[
	Gets UserId from player-like variable.

	@param PlayerLike UserLike
	@within PlayerAPI
	@return number
]=]
function Player:GetUserId(PlayerLike)
	local UserId
	if type(PlayerLike) == "number" then
		UserId = PlayerLike
	elseif type(PlayerLike) == "string" then
		UserId = Players:GetUserIdFromNameAsync(PlayerLike)
	else
		UserId = PlayerLike.UserId
	end

	return UserId
end

--[=[
	Gets player's session data.

	@param PlayerLike UserLike
	@within PlayerAPI
	@return PlayerData
]=]
function Player:GetData(PlayerLike)
	local UserId = self:GetUserId(PlayerLike)
	if not UserId then
		return
	end
	
	if not self.Players[UserId] then
		local Success, PlayerData = DataStore:Load("Player", UserId)
		if not Success then
			return
		end
		
		PlayerData = PlayerData or Data.DataStores.Player
		return PlayerData
	end
	
	return self.Players[UserId].Data
end

--[=[
	Sets player's session data.

	@param PlayerLike UserLike
	@param Key string
	@param Value any
	@within PlayerAPI
	@return boolean | nil
]=]
function Player:SetData(PlayerLike, Key, Value)
	local UserId = self:GetUserId(PlayerLike)
	if not UserId then
		return
	end
	
	if not self.Players[UserId] then
		local Success, PlayerData = DataStore:Load("Player", UserId)
		if not Success then
			return false
		end

		PlayerData = PlayerData or Data.DataStores.Player
		PlayerData[Key] = Value
		
		DataStore:Save("Player", UserId, PlayerData)
		return true
	end
	
	self.Players[UserId][Key] = Value
	return true
end

--[=[
	Logs and executes commands from the specified message.

	@param player Player
	@param Message string
	@param Options OnMessageOptions
	@within PlayerAPI
	@return PlayerData
]=]
function Player:OnMessage(player, Message, Options)
	Options = Options or {}
	Parser = Parser or require(Main.Server.Services.Parser)
	local Filtered = "[Failed to filter message]"
	
	local Success, Response = pcall(function()
		Filtered = TextService:FilterStringAsync(Message, player.UserId, Enum.TextFilterContext.PrivateChat)
	end)
	
	local Log = {
		UserId = player.UserId,
		Time = DateTime.now().UnixTimestamp,
		Message = Success and Filtered:GetNonChatStringForBroadcastAsync() or Filtered
	}
	
	if not Options.NoLog then
		table.insert(Data.ChatLogs, Log)
	end

	local Branches = Parser:Parse(player, Message, true)
	local Success = true
	local Amount = #Branches or 0
	
	local UserData = self.Players[player.UserId]
	local Limit = (not Options.NoLimit and Configuration.CommandCalls ~= 0 and UserData.Data.Rank < Restrictions.CommandCalls) and math.min(Configuration.CommandCalls, 999) or 999
	
	local Index = #self.Players[player.UserId].Session.CommandUsage
	for i, Branch in ipairs(Branches) do
		if self.Players[player.UserId].Session.CommandUsage[Index] >= Limit then
			Popup:New({
				Player = player,
				Type = "Warning",
				Text = "Command calls per minute limit exceeded."
			})
			
			return false
		end
		
		local BranchSuccess = Parser:Call(Branch, true)
		if BranchSuccess then
			self.Players[player.UserId].Session.CommandUsage[Index] += 1
		end
		
		if Success and not BranchSuccess then
			Success = false
		end
	end
	
	self.Players[player.UserId].Session.CommandUsage[Index] = math.min(self.Players[player.UserId].Session.CommandUsage[Index], Limit)
	return Success
end

--[=[
	Binds player to System.

	@private
	@param player Player
	@within PlayerAPI
	@return nil
]=]
function Player:Bind(player)
	if self.Players[player.UserId] then
		warn(`[{self.__type}]: Player with UserId {player.UserId} is already binded.`)
		return
	end
	
	if Data.Shutdown.Enabled then
		player:Kick(Data.Shutdown.Reason)
		return
	end
	
	local BanData = self.API:GetBanData(player)
	if BanData then
		self:__BanPrompt(player, BanData)
		return
	end
	
	local Success, PlayerData = DataStore:Load("Player", player.UserId)
	if not Success then
		warn(`[{self.__type}]: Failed to bind player '{player}' to System. Using default data instead.`)
		PlayerData = Data.DataStores.Player
	end
	
	for i, v in pairs(PlayerSettings) do
		if PlayerData.Settings[i] ~= nil then
			continue
		end
		
		PlayerData.Settings[i] = v
	end
	
	PlayerData.Settings = SettingHandler:SetPlayer(player, PlayerData.Settings)
	local PlayerSession = {
		Listeners = {},
		SessionJoin = tick(),
		Requests = {0},
		CommandUsage = {0},
	}
	
	self.Players[player.UserId] = {
		Data = PlayerData,
		Session = PlayerSession
	}

	for i, Group in ipairs(Configuration.Groups) do
		local Success, Role = pcall(function()
			return player:GetRankInGroup(Group.GroupId)
		end)
		
		if not Success then
			warn(`[{self.__type}]: Unable to get role of player {player.Name} ({player.UserId}) in group with id '{Group.GroupId}'.`)
			continue
		end
		
		for i, RoleData in ipairs(Group.Roles) do
			if RoleData.GroupRank ~= Role then
				continue
			end
			
			self.Players[player.UserId].Data.Rank = RoleData.AdminRank
			break
		end
	end
	
	local RankData = self.API.RankService:FindUser(player.UserId)
	if RankData then
		self.Players[player.UserId].Data.Rank = RankData.Rank
	end
	
	local OwnerId = self.API:GetOwnerId()
	if player.UserId == OwnerId and not workspace:GetAttribute("GA_TestingPlace_IgnoreOwner") then
		self.Players[player.UserId].Data.Rank = 5
	end
	
	if Configuration.Sandbox and (Data.InStudio or Configuration.__GAdmin_TestingPlace_Sandbox_Everywhere) then
		self.Players[player.UserId].Session.__RANK = self.Players[player.UserId].Data.Rank
		self.Players[player.UserId].Data.Rank = Configuration.SandboxRank
	end
end

--[=[
	Unbinds player from System.

	@private
	@param player Player
	@within PlayerAPI
	@return nil
]=]
function Player:UnBind(player)
	if not self.Players[player.UserId] then
		warn(`[{self.__type}]: Player with UserId {player.UserId} is not binded.`)
		return
	end
	
	if Configuration.Sandbox and (Data.InStudio or Configuration.__GAdmin_TestingPlace_Sandbox_Everywhere) then
		self.Players[player.UserId].Data.Rank = self.Players[player.UserId].Session.__RANK
	end
	
	local Success = DataStore:Save("Player", player.UserId, self.Players[player.UserId].Data)
	self.Players[player.UserId] = nil
	
	if not Success then
		warn(`[{self.__type}]: Failed to unbind player '{player}' from System. Data loss may occurred.`)
	end
end

return Proxy