--== << Services >>
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local GroupService = game:GetService("GroupService")

local Main = script:FindFirstAncestor("MainModule")
local Data =  require(Main.Server.Data)

local RankService = require(Data.Shared.Services.Rank)
local DataStore = require(Main.Server.Services.DataStore)
local Configuration = require(Data.Settings.Main)
--==

local Proxy = newproxy(true)

--[=[
	@class ServerAPI
	@server
	@tag API
	GAdmin API for server-side.
	
	Location: `GAdminV2.MainModule.Server.Services.API`
]=]

--[=[
	@interface ServerAPI
	@within ServerAPI

	@field __type string
	@field __Messages table

	@field PlayerAPI PlayerAPI
	@field RankService RankService

	@field __EncryptMessageEnum (Topic: string, Item: unknown) -> unknown,
	@field __DecryptMessageEnum (Topic: string, Id: unknown) -> unknown,
	@field SetMessage (Topic: string, Enums: table) -> nil,
	@field ReceiveMessage (Topic: string, Function: (Data: MessageData) -> ()) -> nil,
	@field SendMessage (Topic: string, Data: table) -> boolean,
	@field GetOwnerId () -> number,
	@field Shutdown (Reason: string) -> nil,
	@field Ban (UserLike: UserLike, Options: BanOptions) -> boolean,
	@field UnBan (UserLike: UserLike, Type: string) -> boolean,
	@field GetBanData (UserLike: UserLike, Type: string) -> BanData,
	@field IsBanned (UserLike: UserLike, Type: string) -> boolean,
	@field GetBanlist (Type: string) -> table,
	@field GetPrefix (player: UserLike) -> string,
	@field SetPrefix (player: UserLike, Prefix: string) -> nil,
	@field GetRank (player: UserLike) -> RankData,
	@field SetRank (player: UserLike, Rank: RankLike, Server: boolean) -> nil
]=]

--[=[
	@interface BanOptions
	@field Reason string -- Ban reason.
	@field PrivateReason string -- Private ban reason.
	@field Time number | "inf" -- Ban time.
	@field Moderator number -- Moderator id.
	@field API boolean -- Use Roblox ban API.
	@field Locally boolean -- Ban locally.
	@field ApplyToUniverse boolean -- Apply to universe.
	@field ExcludeAltAccount boolean -- Exclude alt account.
	@within ServerAPI
]=]

--[=[
	@interface BanData
	@field Moderator string -- Moderator id.
	@field Reason string -- Ban reason.
	@field Time string -- Ban time.
	@field On string -- When did user get banned.
	@field API boolean -- Use Roblox ban API.
	@field Locally boolean -- Ban user on server.
	@field ApplyToUniverse boolean -- Ban user in every place of the game.
	@field Type string -- Ban type.
	@field PrivateReason string -- For moderators only.
	@within ServerAPI
]=]

--[=[
	@type MessageData table
	@within ServerAPI
]=]

local API = getmetatable(Proxy)
API.__type = "GAdmin API"
API.__metatable = "[GAdmin API]: Metatable methods are restricted."

--[=[
	Topics enums.
	@prop __Messages table
	@private
	@within ServerAPI
]=]
API.__Messages = {}

--[=[
	@prop PlayerAPI PlayerAPI
	@within ServerAPI
]=]
API.PlayerAPI = require(Main.Server.Services.Player)

--[=[
	@prop RankService RankService
	@within ServerAPI
]=]
API.RankService = RankService

function API:__tostring()
	return self.__type
end

function API:__index(Key)
	return API[Key]
end

function API:__newindex(Key, Value)
	API[Key] = Value
end

--[=[
	Encrypts message enum.

	@private
	@param Topic string -- Topic to send thru MessagingService
	@param Item unknown -- Item to encrypt.
	@within ServerAPI
	@return unknown
]=]
function API:__EncryptMessageEnum(Topic, Item)
	if not Topic or not self.__Messages[Topic] then
		return
	end
	
	return self.__Messages[Topic][Item]
end

--[=[
	Decrypts message enum.

	@private
	@param Topic string -- Topic to send thru MessagingService
	@param Id unknown -- Id to decrypt.
	@within ServerAPI
	@return unknown
]=]
function API:__DecryptMessageEnum(Topic, Id)
	if not Topic or not self.__Messages[Topic] then
		return
	end
	
	for EnumItem, Value in pairs(self.__Messages[Topic]) do
		if Value ~= Id then
			continue
		end
		
		return EnumItem
	end
end

--[=[
	Sets enums for specific topic of MessaginService.

	@param Topic string -- Topic to send thru MessagingService
	@param Enums table -- Compress strings mentioned in Enums to numbers for memory saving.
	@within ServerAPI
	@return nil
]=]
function API:SetMessage(Topic, Enums)
	local TopicType = type(Topic)
	local EnumsType = type(Enums)
	
	if TopicType ~= "string" then
		warn(`[{self.__type}]: Topic expected, got '{TopicType}'.`)
		return
	end
	
	if EnumsType ~= "table" then
		warn(`[{self.__type}]: Message {Topic} :: Table with enums expected, got '{EnumsType}'`)
		return
	end
	
	local Items = {}
	for i, Item in ipairs(Enums) do
		if type(Item) ~= "string" then
			warn(`[{self.__type}]: Message {Topic} :: Enum item '{Item}' is invalid.`)
			continue
		end
		
		Items[Item] = `E{i}`
	end
	
	self.__Messages[Topic] = Items
end

--[=[
	Listens for messages sent thru MessagingService.

	Takes up one Message Subscription slot.

	@param Topic string -- Topic to send thru MessagingService
	@param Function (Data: MessageData) -> () -- Function to execute when message is received.
	@within ServerAPI
	@return nil
]=]
function API:ReceiveMessage(Topic, Function)
	Topic = Topic or "GAdmin_Global"
	local Success, Connection = pcall(function()
		return MessagingService:SubscribeAsync(Topic, function(Message)
			local Data = {}
			for Key, Item in pairs(Message.Data) do
				local EnumItem = self:__DecryptMessageEnum(Topic, Item)
				Data[Key] = EnumItem or Item
			end
			
			Function(Data)
		end)
	end)
end

--[=[
	Sends message using MessagingService.

	@param Topic string -- Topic to send thru MessagingService
	@param Data table -- Data to send thru MessagingService
	@within ServerAPI
	@return boolean
]=]
function API:SendMessage(Topic, Data)
	Topic = Topic or "GAdmin_Global"
	for Index, Item in pairs(Data) do
		local EnumItem = self:__EncryptMessageEnum(Topic, Item)
		if not EnumItem then
			continue
		end
		
		Data[Index] = EnumItem
	end
	
	local Success, Response = pcall(function()
		MessagingService:PublishAsync(Topic, Data)
	end)
	
	if not Success then
		warn(`[{self.__type}]: Message {Topic} :: {Response}`)
	end
	
	return Success
end

--[=[
	Returns owner id of the game.

	@within ServerAPI
	@return number
]=]
function API:GetOwnerId()
	if game.CreatorType == Enum.CreatorType.Group then
		local GroupInfo = GroupService:GetGroupInfoAsync(game.CreatorId)
		return GroupInfo.Owner.Id
	end
	
	return game.CreatorId
end

--[=[
	Shutdown current server.

	@param Reason string -- Reason for shutdown.
	@within ServerAPI
	@return nil
]=]
function API:Shutdown(Reason)
	Reason = Reason or "No Reason."
	for i, player in ipairs(Players:GetPlayers()) do
		player:Kick(`Server has been shut down. Reason: {Reason}`)
	end
	
	Data.Shutdown = {
		Enabled = true,
		Reason = Reason
	}
end

--[=[
	Bans specified player.

	To API ban player, you need to do the following:
	```lua
	API:Ban(1556153247, {
		Reason = "Bully",
		PrivateReason = "Don't unban.",
		Time = "inf",
		Moderator = 549319173,
		API = true,
		ApplyToUniverse = true,
		ExcludeAltAccount = true
	})
	```
	@yields
	@param UserLike UserLike -- User to ban.
	@param Options BanOptions -- Ban options.
	@within ServerAPI
	@return boolean
]=]
function API:Ban(UserLike, Options)
	local UserId = self.PlayerAPI:GetUserId(UserLike)
	if self:GetBanData(UserId) then
		warn(`[{self.__type}]: User with id {UserId} is already banned.`)
		return false, `User with id '{UserId}' is already banned.`
	end
	
	local Limit = 86400 * 365 * 99
	Options = Options or {}
	
	Options.Reason = Options.Reason and tostring(Options.Reason) or "No reason."
	Options.PrivateReason = Options.PrivateReason and tostring(Options.PrivateReason) or Options.Reason
	Options.Time = Options.Time or 3600
	
	local IsString = type(Options.Time) == "string"
	local IsInfinite = IsString and Options.Time:lower():find("inf") or false
	
	if IsInfinite then
		Options.Time = Limit
	end
	
	if IsString and not IsInfinite then
		return false, "Time must be a number."
	end
	
	if Options.Moderator then
		Options.Moderator = type(Options.Moderator) == "number" and Options.Moderator or Players:GetUserIdFromNameAsync(Options.Moderator)
	end
	
	local Timestamp = DateTime.now().UnixTimestamp
	local Ban = {
		tostring(Options.Moderator), -- Moderator
		tostring(Options.Reason), -- Reason
		tostring(Timestamp + math.clamp(Options.Time, 1, Limit)), -- Time
		tostring(Timestamp), -- On
		Options.API, -- API
		Options.Locally, -- Locally
		Options.ApplyToUniverse, -- ApplyToUniverse
		"Global", -- Type
		Options.PrivateReason, -- ModHint
	}

	if Options.Locally then
		Data.ServerBans[UserId] = Ban
		local player = Players:GetPlayerByUserId(UserId)
		
		if not player then
			return
		end
		
		self.PlayerAPI:__BanPrompt(player, Ban)
		return true
	end
	
	if Options.API then
		local Success, Response = pcall(function()
			Players:BanAsync({
				UserIds = {UserId},
				ApplyToUniverse = Options.ApplyToUniverse,
				DisplayReason = Options.Reason,
				PrivateReason = Options.PrivateReason,
				ExcludeAltAccount = Options.ExcludeAltAccount,
			})
		end)
		
		if not Success then
			warn(`[{self.__type}]: BanAsync :: {Response}`)
		end
	end
	
	local Banlist = self:GetBanlist("Global")
	Banlist[tostring(UserId)] = Ban
	Data.BanlistCache = Banlist
	
	local Success = DataStore:Save("System", "Banlist", Banlist)
	self:SendMessage("GA_GlobalBanlistUpdate", {})
	
	if Success then
		self:SendMessage("GA_PlayerBan", {
			UserId = UserId,
			Ban = Ban
		})
	end
	
	return Success
end

--[=[
	Unbans specified player.

	@yields
	@param UserLike UserLike -- User to unban.
	@param Type "Global" | "Server" -- Type of unban.
	@within ServerAPI
	@return boolean
]=]
function API:UnBan(UserLike, Type)
	Type = Type or "Global"
	if not table.find({"Server", "Global"}, Type) then
		warn(`[{self.__type}]: Unban type '{Type}' is invalid.`)
		return false, `Unban type '{Type}' is invalid.`
	end
	
	local UserId = tostring(self.PlayerAPI:GetUserId(UserLike))
	local Banlist = self:GetBanlist(Type)
	
	if not Banlist[UserId] then
		warn(`[{self.__type}]: User with id {UserId} is not banned.`)
		return false, `User with id {UserId} is not banned.`
	end
	
	if Type == "Server" then
		Data.ServerBans[UserId] = nil
		Data.BanlistCache = self:GetBanlist("Formatted")
		return true
	end
	
	if Banlist[UserId].API then
		local Success, Response = pcall(function()
			Players:UnbanAsync({
				UserIds = {UserId},
				ApplyToUniverse = Banlist[UserId].ApplyToUniverse
			})
		end)
		
		if not Success then
			warn(`[{self.__type}]: UnBan :: {Response}`)
		end
	end
	
	Banlist[UserId] = nil
	Data.BanlistCache = Banlist
	
	local Success = DataStore:Save("System", "Banlist", Banlist)
	self:SendMessage("GA_GlobalBanlistUpdate", {})
	
	return Success
end

--[=[
	Returns ban data of specified player.

	@yields
	@param UserLike UserLike -- User to get ban data from.
	@param Type "Global" | "Server" -- Type of unban.
	@within ServerAPI
	@return BanData
]=]
function API:GetBanData(UserLike, Type)
	local Banlist = self:GetBanlist(Type)
	local UserId = self.PlayerAPI:GetUserId(UserLike)
	
	if not Banlist or not UserId then
		return
	end
	
	return Banlist[tostring(UserId)]
end

--[=[
	Returns if specified player is banned.

	@yields
	@param UserLike UserLike -- User to check if banned.
	@param Type "Global" | "Server" -- Type of unban.
	@within ServerAPI
	@return boolean
]=]
function API:IsBanned(UserLike, Type)
	local Banlist = self:GetBanlist(Type)
	local UserId = self.PlayerAPI:GetUserId(UserLike)

	if not Banlist or not UserId then
		return false
	end

	return Banlist[tostring(UserId)] ~= nil
end

--[=[
	Returns banlist.

	@yields
	@param Type "Global" | "Server" | "Both" | "Formatted" -- Type of banlist.
	@within ServerAPI
	@return table
]=]
function API:GetBanlist(Type)
	Type = Type or "Both"
	local Banlist = {}
	
	if Type == "Formatted" then
		local Banlist1 = self:GetBanlist("Global")
		local Banlist2 = self:GetBanlist("Server")
		
		for i, v in pairs(Banlist1) do
			v[8] = "Global"
			Banlist[i] = v
		end

		for i, v in pairs(Banlist2) do
			if Banlist[i] then
				continue
			end
			
			v[8] = "Server"
			Banlist[i] = v
		end
	end
	
	if Type == "Both" then
		local Banlist1 = self:GetBanlist("Global")
		local Banlist2 = self:GetBanlist("Server")
		
		for i, v in pairs(Banlist1) do
			Banlist[i] = v
		end
		
		for i, v in pairs(Banlist2) do
			if Banlist[i] then
				continue
			end
			
			Banlist[i] = v
		end
	end
	
	if Type == "Global" then
		local Success, GivenBanlist = DataStore:Load("System", "Banlist")
		Banlist = Success and GivenBanlist or {}
	end
	
	if Type == "Server" then
		Banlist = Data.ServerBans
	end
	
	local Timestamp = DateTime.now().UnixTimestamp
	for UserId, BanData in pairs(Banlist) do
		local BanData = _G.GAdmin.__GetBanData(BanData)
		if Timestamp < tonumber(BanData.Time) then
			continue
		end
		
		if BanData.API then
			pcall(function()
				Players:UnbanAsync({
					UserIds = {UserId},
					ApplyToUniverse = BanData.ApplyToUniverse
				})
			end)
		end
		
		Banlist[UserId] = nil
	end
	
	if Type == "Server" then
		Data.ServerBans = Banlist
	end
	
	return Banlist
end

--[=[
	Returns player's prefix.
	@param player UserLike -- Player to get prefix from.
	@within ServerAPI
	@return string
]=]
function API:GetPrefix(player)
	local PlayerData = self.PlayerAPI:GetData(player)
	if not PlayerData then
		return
	end
	
	return PlayerData.Prefix
end

--[=[
	Sets new prefix for given player.
	@param player UserLike -- Player to set prefix for.
	@param Prefix string -- New prefix.
	@within ServerAPI
	@return nil
]=]
function API:SetPrefix(player, Prefix)
	if type(Prefix) ~= "string" then
		warn(`[{self.__type}]: Prefix must be type of string, not {type(Prefix)}.`)
		return
	end
	
	local Success = self.PlayerAPI:SetData(player, "Prefix", Prefix)
	if Success then
		return
	end
	
	warn(`[{self.__type}]: Unable to set new prefix for player {player.Name}.`)
end

--[=[
	Returns player's rank.
	@param player UserLike -- Player to get rank from.
	@within ServerAPI
	@return RankData
]=]
function API:GetRank(player)
	if Configuration.Sandbox and (Data.InStudio or Configuration.__GAdmin_TestingPlace_Sandbox_Everywhere) then
		return RankService:Find(Configuration.SandboxRank)
	end
	
	local PlayerData = self.PlayerAPI:GetData(player)
	if not PlayerData then
		return
	end
	
	local Rank = PlayerData.Rank
	local RankData = RankService:Find(Rank)
	
	return RankData
end

--[=[
	Sets new rank for given player.
	@yields
	@param player UserLike -- Player to set rank for.
	@param Rank RankLike -- New rank.
	@param Server boolean -- Set rank for current server only.
	@within ServerAPI
	@return nil
]=]
function API:SetRank(player, Rank, Server)
	local RankData = RankService:Find(Rank)
	if not RankData then
		warn(`[{self.__type}]: Rank '{Rank}' is invalid.`)
		return
	end
	
	local UserId = self.PlayerAPI:GetUserId(player)
	if Server then
		self.PlayerAPI.Players[UserId].Session.__RANK = Server and self.PlayerAPI.Players[UserId].Data.Rank or nil
		self.PlayerAPI.Players[UserId].Data.Rank = RankData.Rank
	end
	
	RankService:SetUser(RankData.Rank, UserId, Server)
	--if Success then
	--	return
	--end

	--warn(`[{self.__type}]: Unable to set new rank for player {player.Name}.`)
end

return Proxy