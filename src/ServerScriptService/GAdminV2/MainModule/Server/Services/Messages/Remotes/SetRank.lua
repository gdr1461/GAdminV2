--== << Services >>
local Data = require(_G.GAdmin.Path.Server.Data)
local API = require(Data.Server.Services.API)

local Restrictions = require(Data.Settings.Restrictions)
local RankService = require(Data.Shared.Services.Rank)
--==

return {
	Add = function(player, RankData, Locally)
		local PlayerRank = API:GetRank(player)
		--== CODE 1: No player restriction.
		if not PlayerRank or PlayerRank.Rank < Restrictions.Ranks.ChangeRanks then
			return {1, Restrictions.Ranks.ChangeRanks}
		end

		--== CODE 2: RankData is invalid.
		if RankData then
			RankData.Color = RankData.Color or Data.RankInterface.Color
			RankData.Color = RankData.Color:ToHex()
		end
		
		if not RankData or not RankData.Name or not RankData.Rank or not RankData.Color or RankService:Find(RankData.Name) or RankService:Find(RankData.Rank) then
			return {2, RankData}
		end

		--== CODE 3: Unable to set rank higher than owner role.
		if RankData.Rank >= 5 then
			return {3}
		end
		
		--== CODE 4: Player rank needs to be higher than given rank.
		if RankData.Rank >= PlayerRank.Rank then
			return {4, RankData}
		end
		
		--== CODE 5: User is invalid.
		--== CODE 6: User rank is higher than yours.
		local UserIds = {}
		for i, UserLike in ipairs(RankData.Players) do
			local UserId = tonumber(UserLike, 10) or game.Players:GetUserIdFromNameAsync(UserLike)
			if not UserId then
				return {5, UserLike}
			end
			
			local UserRank = API:GetRank(UserId)
			if UserRank.Rank >= PlayerRank.Rank then
				return {6, {UserLike, UserRank.Rank}}
			end
			
			table.insert(UserIds, UserId)
		end
		
		RankData.MadeBy = tostring(player.UserId)
		RankService:Add(RankData, Locally)
		
		if #UserIds > 0 then
			RankService:AddUsers(RankData.Name, UserIds)
		end
		
		API:SendMessage("GA_GlobalRankUpdate", {"Add"})
		return {0}
	end,
	
	Change = function(player, ChangeData, Locally)
		local RankData = {
			Name = ChangeData.Name,
			Rank = ChangeData.Rank,
			Players = ChangeData.Players,
			Color = ChangeData.Color,
		}
		
		local PlayerRank = API:GetRank(player)
		--== CODE 1: No player restriction.
		if not PlayerRank or PlayerRank.Rank < Restrictions.Ranks.ChangeRanks then
			return {1, Restrictions.Ranks.ChangeRanks}
		end

		if RankData then
			RankData.Color = RankData.Color or Data.RankInterface.Color
			RankData.Color = RankData.Color:ToHex()
		end
		
		local TagData = RankService:Find(ChangeData.Tag)
		--== CODE 2: RankData is invalid.
		if not RankData or not RankData.Name or not RankData.Rank or not RankData.Color or not TagData then
			return {2, RankData}
		end

		--== CODE 3: Unable to set rank higher than owner role.
		if RankData.Rank >= 5 then
			return {3}
		end

		--== CODE 4: Player rank needs to be higher than given rank.
		if RankData.Rank >= PlayerRank.Rank or TagData.Rank >= PlayerRank.Rank then
			return {4, RankData}
		end

		--== CODE 5: User is invalid.
		--== CODE 6: User rank is higher than yours.
		local UserIds = {}
		for i, UserLike in ipairs(RankData.Players) do
			local UserId = tonumber(UserLike, 10) or game.Players:GetUserIdFromNameAsync(UserLike)
			if not UserId then
				return {5, UserLike}
			end

			local UserRank = API:GetRank(UserId)
			if UserRank.Rank >= PlayerRank.Rank then
				return {6, {UserLike, UserRank.Rank}}
			end

			table.insert(UserIds, UserId)
		end

		RankData.MadeBy = tostring(player.UserId)
		RankService:Change(ChangeData.Tag, RankData, Locally)

		if #UserIds > 0 then
			RankService:AddUsers(RankData.Name, UserIds)
		end

		API:SendMessage("GA_GlobalRankUpdate", {"Change"})
		return {0}
	end,
	
	Remove = function(player, RankLike, Locally)
		local PlayerRank = API:GetRank(player)
		--== CODE 1: No player restriction.
		if not PlayerRank or PlayerRank.Rank < Restrictions.Ranks.ChangeRanks then
			return {1, Restrictions.Ranks.ChangeRanks}
		end
		
		--== CODE 2: RankData is invalid.
		local RankData = RankService:Find(RankLike)
		if not RankData then
			return {2, RankLike}
		end
		
		--== CODE 3: Unable to remove rank higher than owner role.
		if RankData.Rank >= 5 then
			return {3}
		end
		
		--== CODE 4: Player rank needs to be higher than given rank.
		if RankData.Rank >= PlayerRank.Rank then
			return {4, RankData}
		end
		
		RankService:Remove(RankData.Name, Locally)
		API:SendMessage("GA_GlobalRankUpdate", {"Remove"})
		return {0}
	end,
}