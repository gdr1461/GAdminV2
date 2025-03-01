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
local API = getmetatable(Proxy)

API.__type = "GAdmin API"
API.__metatable = "[GAdmin API]: Metatable methods are restricted."
API.__Messages = {}

API.PlayerAPI = require(Main.Server.Services.Player)
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

function API:__EncryptMessageEnum(Topic, Item)
	if not Topic or not self.__Messages[Topic] then
		return
	end
	
	return self.__Messages[Topic][Item]
end

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

--[[
	Creates Enums that will automaticly compress given strings in the table for optimization purposes.
]]
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

--[[
	Recieves message from the other server.
]]
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

--[[
	Sends message to all of the other servers.
]]
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

--[[
	Gets owner's id of current game.
]]
function API:GetOwnerId()
	if game.CreatorType == Enum.CreatorType.Group then
		local GroupInfo = GroupService:GetGroupInfoAsync(game.CreatorId)
		return GroupInfo.Owner.Id
	end
	
	return game.CreatorId
end

--[[
	Shutdowns current server.
]]
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

--[[
	Bans player.
]]
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

--[[
	Unbans player.
]]
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

--[[
	Returns ban data of user if any.
]]
function API:GetBanData(UserLike, Type)
	local Banlist = self:GetBanlist(Type)
	local UserId = self.PlayerAPI:GetUserId(UserLike)
	
	if not Banlist or not UserId then
		return
	end
	
	return Banlist[tostring(UserId)]
end

--[[
	Returns boolean based off if user is banned or not.
]]
function API:IsBanned(UserLike, Type)
	local Banlist = self:GetBanlist(Type)
	local UserId = self.PlayerAPI:GetUserId(UserLike)

	if not Banlist or not UserId then
		return false
	end

	return Banlist[tostring(UserId)] ~= nil
end

--[[
	Returns updated banlist.
]]
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

--[[
	Returns player's command prefix.
]]
function API:GetPrefix(player)
	local PlayerData = self.PlayerAPI:GetData(player)
	if not PlayerData then
		return
	end
	
	return PlayerData.Prefix
end

--[[
	Sets new prefix for given player.
]]
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

--[[
	Returns player's rank data.
]]
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

--[[
	Sets new rank for given player.
]]
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