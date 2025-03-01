--== << Services >>

local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local Side = Players.LocalPlayer == nil and "Server" or "Client"
local Main = script:FindFirstAncestor("GAdminShared")

local Configuration = Main.Settings
local MainSettings = require(Configuration.Main)
local RankSettingsClone = Configuration.Ranks:Clone()

local Cache = require(Main.Client.Services.Framework.Cache)
local RankSettingsCloned = require(RankSettingsClone)
local RankSettings = require(Configuration.Ranks)

local DataStore = Side == "Server" and require(_G.GAdmin.Path.Server.Services.DataStore) or nil
local Data = Side == "Server" and require(_G.GAdmin.Path.Server.Data) or nil

local PlayerService = Side == "Server" and require(_G.GAdmin.Path.Server.Services.Player) or nil
local Remote = require(Main.Shared.Services.Remote)

--==

local Proxy = newproxy(true)
local Rank = getmetatable(Proxy)

Rank.__type = "GAdmin Rank"
Rank.__metatable = "[GAdmin Rank]: Metatable methods are restricted."

Rank.RecentPlayers = {}
Rank.Temporary = {}

function Rank:__tostring()
	return self.__type
end

function Rank:__index(Key)
	return Rank[Key]
end

function Rank:__newindex(Key, Value)
	Rank[Key] = Value
end

--[[
	Saves current rank cache to the datastore.
]]
function Rank:Save()
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to save ranks from client.`)
		return
	end
	
	local Ranks = {}
	for Index, RankData in ipairs(RankSettings.Ranks) do
		if RankData.Temporary or table.find(Ranks, RankData) then
			continue
		end
		
		for Order, UserLike in ipairs(RankData.Players) do
			local UserId = type(UserLike) == "number" and UserLike or game.Players:GetUserIdFromNameAsync(UserLike)
			if not UserId then
				continue
			end
			
			RankSettings.Ranks[Index].Players[Order] = UserId
		end
		
		RankSettings.Ranks[Index].MadeBy = RankSettings.Ranks[Index].MadeBy or tostring(PlayerService.API:GetOwnerId())
		table.insert(Ranks, RankSettings.Ranks[Index])
	end
	
	DataStore:Save("System", "Ranks", Ranks)
	return self:Reload()
end

--[[
	Loads ranks that was added in-game via panel.
]]
function Rank:Reload()
	task.wait()
	if Side == "Client" then
		local Ranks = Remote:Fire("GetRanks")
		if not Ranks then
			return
		end

		RankSettings.Ranks = Ranks
		return
	end

	local Success, Ranks = DataStore:Load("System", "Ranks")
	if not Success then
		return
	end
	
	for i, RankData in ipairs(Ranks) do
		local Constant = self:Find(RankData.Name, true)
		if Constant then
			for Key, Value in pairs(Constant) do
				if RankData[Key] then
					continue
				end

				RankData[Key] = Value
			end
			
			continue
		end
		
		for Key, Value in pairs(Data.RankInterface) do
			if RankData[Key] then
				continue
			end

			RankData[Key] = Value
		end
	end
	
	for i, RankData in ipairs(self.Temporary) do
		local Constant = self:Find(RankData.Name, true)
		if Constant then
			for Key, Value in pairs(Constant) do
				if RankData[Key] then
					continue
				end

				RankData[Key] = Value
			end

			continue
		end
		
		table.insert(Ranks, RankData)
	end

	RankSettings.Ranks = Ranks
	Data.RankCache = Ranks
	
	table.sort(RankSettings.Ranks, function(Rank1, Rank2)
		return Rank1.Rank > Rank2.Rank
	end)
	
	--self.Temporary = {}
	return RankSettings.Ranks
end

--[[
	Add group of ranks in-game.
]]
function Rank:BatchAdd(Data, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to add ranks from client.`)
		return
	end
	
	if MainSettings.ConstantRanks or type(Data) ~= "table" then
		return
	end
	
	for i, Rank in ipairs(Data) do
		self:Add(Rank, true)
	end
	
	if not Locally then
		self:Save()
	end
end

--[[
	Add new rank in-game.
]]
function Rank:Add(Data, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to add rank from client.`)
		return
	end
	
	if MainSettings.ConstantRanks or type(Data) ~= "table" or not Data.Name or not Data.Rank or Data.Rank >= 5 then
		return
	end
	
	Data.Name = Data.Name:sub(1, 20)
	Data.Players = {}
	
	Data.Temporary = Locally
	table.insert(RankSettings.Ranks, Data)
	
	table.sort(RankSettings.Ranks, function(Rank1, Rank2)
		return Rank1.Rank > Rank2.Rank
	end)
	
	table.insert(self.Temporary, Data)
	table.sort(self.Temporary, function(Rank1, Rank2)
		return Rank1.Rank > Rank2.Rank
	end)
	
	if not Locally then
		self:Save()
	end
end

--[[
	Changes rank in-game via panel.
]]
function Rank:Change(RankLike, Data, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to change rank from client.`)
		return
	end
	
	if MainSettings.ConstantRanks or type(Data) ~= "table" or not Data.Name or not Data.Rank or Data.Rank >= 5 then
		return
	end
	
	Data.Name = Data.Name:sub(1, 20)
	Data.Players = {}
	
	local RankData, Index = self:Find(RankLike)
	Data.Temporary = RankData.Temporary
	
	local _, TempIndex = self:Find(RankLike, nil, nil, true)
	Locally = Data.Temporary
	
	if TempIndex and RankData.Rank < 5 then
		table.remove(self.Temporary, TempIndex)
		table.insert(self.Temporary, Data)
	end
	
	if not Index or RankData.Rank >= 5 then
		return
	end
	
	table.remove(RankSettings.Ranks, Index)
	table.insert(RankSettings.Ranks, Index, Data)
	
	table.sort(RankSettings.Ranks, function(Rank1, Rank2)
		return Rank1.Rank > Rank2.Rank
	end)
	
	if not Locally then
		self:Save()
	end
end

--[[
	Removes rank in-game via panel.
]]
function Rank:Remove(RankLike, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to add rank from client.`)
		return
	end

	if MainSettings.ConstantRanks then
		return
	end
	
	local RankData, Index = self:Find(RankLike, nil, true)
	local _, TempIndex = self:Find(RankLike, nil, nil, true)
	
	if TempIndex and RankData.Rank < 5 then
		table.remove(self.Temporary, TempIndex)
	end
	
	if not RankData then
		return
	end
	
	table.remove(RankSettings.Ranks, Index)
	table.sort(RankSettings.Ranks, function(Rank1, Rank2)
		return Rank1.Rank >= Rank2.Rank
	end)
	
	if not Locally then
		self:Save()
	end
end

--[[
	Add new users to the rank.
]]
function Rank:AddUsers(Rank, UserIds, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to add user from client.`)
		return
	end

	local TempRankData = self:Find(Rank)
	if not TempRankData then
		return
	end
	
	for i, UserId in ipairs(UserIds) do
		self:RemoveUser(UserId, true)
		for i, RankData in ipairs(RankSettings.Ranks) do
			if RankData.Rank ~= TempRankData.Rank then
				continue
			end

			table.insert(RankSettings.Ranks[i].Players, UserId)
			break
		end
	end
	
	Data.Cache = RankSettings
	if not Locally then
		self:Save()
	end
end

--[[
	Removes users from all of the ranks that they're specified in.
]]
function Rank:RemoveUsers(Rank, UserIds, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to remove user from client.`)
		return
	end

	for i, UserId in ipairs(UserIds) do
		for i, RankData in ipairs(RankSettings.Ranks) do
			local Index = table.find(RankData.Players, UserId)
			if not Index then
				continue
			end

			table.remove(RankSettings.Ranks[i].Players, Index)
		end
	end

	Data.Cache = RankSettings
	if not Locally then
		self:Save()
	end
end

--[[
	Combines RemoveUser and AddUser together.
]]
function Rank:SetUser(Rank, UserId, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to set user from client.`)
		return
	end
	
	self:RemoveUser(UserId, Locally)
	self:AddUser(Rank, UserId, Locally)
end

--[[
	Add new user to the rank.
]]
function Rank:AddUser(Rank, UserId, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to add user from client.`)
		return
	end
	
	local Success = pcall(function()
		Players:GetNameFromUserIdAsync(UserId)
	end)
	
	if not Success then
		return
	end
	
	local TempRankData = self:Find(Rank)
	if not TempRankData then
		return
	end
	
	self:RemoveUser(UserId, true)
	for i, RankData in ipairs(RankSettings.Ranks) do
		if RankData.Rank ~= TempRankData.Rank then
			continue
		end
		
		table.insert(RankSettings.Ranks[i].Players, UserId)
		break
	end
	
	Data.Cache = RankSettings
	if not Locally then
		self:Save()
	end
end

--[[
	Removes user from all of the ranks that he's specified in.
]]
function Rank:RemoveUser(UserId, Locally)
	if Side == "Client" then
		warn(`[{self.__type}]: Unable to remove user from client.`)
		return
	end
	
	local Success = pcall(function()
		Players:GetNameFromUserIdAsync(UserId)
	end)
	
	if not Success then
		return
	end
	
	for i, RankData in ipairs(RankSettings.Ranks) do
		local Index = table.find(RankData.Players, UserId)
		if not Index then
			continue
		end

		table.remove(RankSettings.Ranks[i].Players, Index)
	end
	
	Data.Cache = RankSettings
	if not Locally then
		self:Save()
	end
end

--[[
	Returns rank data of the rank that specified user has.
]]
function Rank:FindUser(UserId)
	local Success = pcall(function()
		Players:GetNameFromUserIdAsync(UserId)
	end)
	
	if not Success then
		return
	end
	
	for i, RankData in ipairs(RankSettings.Ranks) do
		local Users = self:GetUsers(RankData.Rank)
		if not Users then
			continue
		end
		
		if not table.find(Users, UserId) then
			continue
		end
		
		return RankData
	end
	
	return self:Find(0)
end

--[[
	Finds user with specified rank.
]]
function Rank:HasRank(Rank, UserId)
	local Users = self:GetUsers(Rank)
	if not Users then
		return
	end
	
	for i, RankUserId in ipairs(Users) do
		if RankUserId ~= UserId then
			continue
		end
		
		return true
	end
	
	return false
end

--[[
	Returns array of user ids that has specified rank.
]]
function Rank:GetUsers(Rank, Type)
	Type = Type or "All"
	local Users = {}
	
	if not self.GetUsersReloadDebounce or tick() - self.GetUsersReloadDebounce > .5 then
		self:Reload()
		self.GetUsersReloadDebounce = tick()
	end
	
	local ConstantData = self:Find(Rank, true)
	local ChangableData = self:Find(Rank) or ConstantData

	if not ChangableData then
		return {}
	end
	
	if Type == "All" then
		local ServerUsers = self:GetUsers(Rank, "Server")
		local GlobalUsers = self:GetUsers(Rank, "Global")
		
		for i, UserLike in ipairs(ServerUsers) do
			table.insert(GlobalUsers, UserLike)
		end
		
		for i, UserLike in ipairs(GlobalUsers) do
			local UserId = tonumber(UserLike, 10) or game.Players:GetUserIdFromNameAsync(UserLike)
			if table.find(Users, UserId) then
				continue
			end

			table.insert(Users, UserId)
		end

		return Users
	end
	
	if Type == "Server" then
		local TempUsers = Side == "Server" and PlayerService.Players or nil
		if Side == "Client" then
			self.RecentPlayers = (not self.GetPlayersDebounce or tick() - self.GetPlayersDebounce > .5) and Remote:Fire("GetPlayers") or self.RecentPlayers
			self.GetPlayersDebounce = tick()
			TempUsers = self.RecentPlayers
		end
		
		for UserId, PlayerData in pairs(TempUsers) do
			if PlayerData.Data.Rank ~= ChangableData.Rank then
				continue
			end

			table.insert(Users, UserId)
		end
		
		return Users
	end
	
	if Type == "Global" then
		local Players = table.clone(ChangableData.Players)
		if ConstantData then
			for i, UserLike in ipairs(ConstantData.Players) do
				table.insert(Players, UserLike)
			end
		end

		for i, UserLike in ipairs(Players) do
			local UserId = tonumber(UserLike, 10) or game.Players:GetUserIdFromNameAsync(UserLike)
			if table.find(Users, UserId) then
				continue
			end

			table.insert(Users, UserId)
		end
		
		return Users
	end
end

--[[
	Returns array table of previous and current rank names.
]]
function Rank:GetArray(Rank, UserId)
	Rank = Rank or 5
	Rank = self:Find(Rank).Rank
	
	local Ranks = {}
	for i, RankConfig in ipairs(RankSettings.Ranks) do
		if RankConfig.Rank > Rank then
			continue
		end
		
		table.insert(Ranks, RankConfig.Name)
	end
	
	return Ranks
end

--[[
	Checks if UserId is in GAdmin Intrenals.
]]
function Rank:IsInternal(UserId)
	return table.find(Cache.VersionLog.Internals, UserId) ~= nil
end

--[[
	Checks if rank data is identical to the source data.
]]
function Rank:IsEquals(RankData, SourceData)
	for i, v in pairs(SourceData) do
		if RankData[i] == v or table.find({"MadeBy", "Players"}, i) then
			continue
		end
		
		return false
	end
	
	return true
end

--[[
	Returns rank data from either rank place or rank name.
]]
function Rank:Find(RankLike, FromCloned, NoCopy, FromTemporary)
	local Name = type(RankLike) == "string" and RankLike or nil
	local Place = type(RankLike) == "number" and RankLike or -99
	
	local Ranks = FromCloned and RankSettingsCloned.Ranks or RankSettings.Ranks
	Ranks = FromTemporary and self.Temporary or Ranks
	
	for i, RankData in ipairs(Ranks) do
		if RankData.Rank ~= Place and (not Name or RankData.Name:lower():sub(1, #Name) ~= Name:lower()) then
			continue
		end
		
		local RankData = (NoCopy and RankData or table.clone(RankData))
		local OwnerId
		
		if RankData.Rank == 5 then
			task.spawn(function()
				if game.CreatorType == Enum.CreatorType.Group then
					local GroupInfo = GroupService:GetGroupInfoAsync(game.CreatorId)
					OwnerId = GroupInfo.Owner.Id
				else
					OwnerId = game.CreatorId
				end

				if not table.find(RankData.Players, OwnerId) then
					table.insert(RankData.Players, OwnerId)
				end
			end)
		end
		
		return RankData, i
	end
end

return Proxy