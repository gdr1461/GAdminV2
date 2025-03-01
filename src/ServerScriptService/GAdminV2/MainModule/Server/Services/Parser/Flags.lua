--== << Services >>
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Main = script:FindFirstAncestor("Server")
local Data = require(Main.Data)

local API = require(Main.Services.API)
local FilterHandler = require(Data.Shared.Services.Core.Filter)
--==

return {
	PlayerOther = {
		Type = {"Player", "number"},
		Return = "Success",

		Requirements = function(Command, Argument, Arguments)
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") or table.find(Arguments[Argument.Index].Types, "number")
			return {
				Success = IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Player'.`
			}
		end,

		Method = function(Caller, Argument, Data)
			local UserId = typeof(Argument) == "Instance" and Argument.UserId or tonumber(Argument)
			return Caller.UserId ~= UserId, `Player can't be yourself.`
		end
	},
	
	PlayerClient = {
		Type = {"Player"},
		Return = "SideControl",
		
		Requirments = function(Command, Argument, Arguments)
			for i, OtherArgument in ipairs(Arguments) do
				if Argument == OtherArgument or not table.find(OtherArgument.Flags, "PlayerSide") then
					continue
				end
				
				return {
					Success = false,
					Response = "PlayerClient flag can only be used once per command."
				}
			end
			
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") or table.find(Arguments[Argument.Index].Types, "number")
			return {
				Success = IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Player'.`
			}
		end,
		
		Method = function(Caller, Argument, Data)
			return Argument
		end,
	},
	
	PlayerOnline = {
		Type = {"Player", "number"},
		Return = "Success",
		
		Requirements = function(Command, Argument, Arguments)
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") or table.find(Arguments[Argument.Index].Types, "number")
			return {
				Success = IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Player'.`
			}
		end,
		
		Method = function(Caller, Argument, Data)
			return typeof(Argument) == "Instance" or (type(Argument) == "table" and Argument.Call), `Player '<font color="#ffbfaa">{Argument}</font>' must be online.`
		end
	},
	
	PlayerOffline = {
		Type = {"Player", "number"},
		Return = "Success",
		
		Requirements = function(Command, Argument, Arguments)
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") or table.find(Arguments[Argument.Index].Types, "number")
			return {
				Success = IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Player'.`
			}
		end,
		
		Method = function(Caller, Argument, Data)
			return type(Argument) == "number" and Players:GetPlayerByUserId(Argument) == nil, `Player '<font color="#ffbfaa">{Argument}</font>' must be offline.`
		end,
	},
	
	ToFilter = {
		Type = {"string"},
		Return = "Response",
		
		Requirements = function(Command, Argument, Arguments)
			local IsString = table.find(Arguments[Argument.Index].Types, "string")
			return {
				Success = IsString,
				Response = `Specified flag can only be used with an argument of type 'String'.`
			}
		end,

		
		Method = function(Caller, Argument, Data)
			if type(Argument) ~= "string" then
				return Argument
			end
			
			return FilterHandler:Filter(Argument, Caller.UserId, Enum.TextFilterContext.PublicChat)
		end,
	},
	
	Optional = {
		Type = {"any"},
		Return = "Success",
		
		Method = function(Caller, Argument, Data)
			return true
		end,
	},
	
	RankLower = {
		Type = {"Rank", "Player"},
		Return = "Success",
		
		Requirements = function(Command, Argument, Arguments)
			local IsRank = table.find(Arguments[Argument.Index].Types, "Rank") ~= nil
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") ~= nil
			
			return {
				Success = IsRank or IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Rank' and 'Player'.`
			}
		end,

		Method = function(Caller, Argument, Data)
			local RankData = API:GetRank(Caller)
			local IsRank = typeof(Argument) == "table"
			
			local ArgumentRank = typeof(Argument) == "table" and Argument or API:GetRank(Argument)
			return RankData.Rank > ArgumentRank.Rank, `{IsRank and "Rank" or "Player rank"} '<font color="#ffbfaa">{ArgumentRank.Name}</font>' must be lower than yours.`
		end,
	},
	
	RankHigher = {
		Type = {"Rank", "Player"},
		Return = "Success",
		
		Requirements = function(Command, Argument, Arguments)
			local IsRank = table.find(Arguments[Argument.Index].Types, "Rank") ~= nil
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") ~= nil

			return {
				Success = IsRank or IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Rank' and 'Player'.`
			}
		end,

		Method = function(Caller, Argument, Data)
			local RankData = API:GetRank(Caller)
			local IsRank = typeof(Argument) == "table"

			local ArgumentRank = typeof(Argument) == "table" and Argument or API:GetRank(Argument)
			return RankData.Rank < ArgumentRank.Rank, `{IsRank and "Rank" or "Player rank"} '<font color="#ffbfaa">{ArgumentRank.Name}</font>' must be higher than yours.`
		end,
	},
	
	RankEqual = {
		Type = {"Rank", "Player"},
		Return = "Success",

		Requirements = function(Command, Argument, Arguments)
			local IsRank = table.find(Arguments[Argument.Index].Types, "Rank") ~= nil
			local IsPlayer = table.find(Arguments[Argument.Index].Types, "Player") ~= nil

			return {
				Success = IsRank or IsPlayer,
				Response = `Specified flag can only be used with an argument of type 'Rank' and 'Player'.`
			}
		end,

		Method = function(Caller, Argument, Data)
			local RankData = API:GetRank(Caller)
			local IsRank = typeof(Argument) == "table"

			local ArgumentRank = typeof(Argument) == "table" and Argument or API:GetRank(Argument)
			return RankData.Rank == ArgumentRank.Rank, `{IsRank and "Rank" or "Player rank"} '<font color="#ffbfaa">{ArgumentRank.Name}</font>' must be equals to yours.`
		end,
	},
	
	Infinite = {
		Type = {"string", "Object"},
		Return = "Define",
		
		Requirements = function(Command, Argument, Arguments)
			if not Arguments[Argument.Index + 1] then
				return {
					Success = true
				}
			end
			
			return {
				Success = false,
				Response = `Arguments after '{Argument.Argument.Name}' will be added to it due to specified flag enabled.`
			}
		end,
		
		Method = function(Parser, Branch, Arguments)
			local NewArguments = {}
			local Offset = 0
			
			local IsInfinite = false
			for i, Argument in ipairs(Arguments.Default) do
				local IsValid = table.find(Argument.Types, "string") or table.find(Argument.Types, "Object")
				if not IsValid or not table.find(Argument.Flags, "Infinite") then
					continue
				end
				
				IsInfinite = true
				break
			end
			
			if not IsInfinite then
				return {
					Success = false
				}
			end
			
			for Index, Argument in ipairs(Arguments.Raw) do
				local Previous = Arguments.Default[Index - Offset - 1]
				local Next = Arguments.Default[Index - Offset + 1]
				
				if not Previous or not table.find(Previous.Flags, "Infinite") or (not table.find(Previous.Types, "string") and not table.find(Previous.Types, "Object")) then
					NewArguments[Index - Offset] = Argument
					continue
				end

				if Next and (not table.find(Next.Types, "string") and not table.find(Next.Types, "Object")) then
					NewArguments[Index - Offset] = Argument
					continue
				end
				
				NewArguments[Index - Offset - 1] ..= ` {Argument}`
				Offset += 1
			end
			
			return {
				Success = true,
				Request = NewArguments,
			}
		end,
	}
}