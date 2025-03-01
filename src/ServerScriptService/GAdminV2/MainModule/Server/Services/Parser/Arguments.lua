--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("Server")

local Data = require(Main.Data)
local RankService = require(Data.Shared.Services.Rank)
--==

local function HasProperties(Object, Properties)
	for Property, Value in pairs(Properties) do
		local Success, ObjectValue = pcall(function()
			return Object[Property]
		end)

		if Success and Value == ObjectValue then
			continue
		end

		return false
	end
	
	return true
end

return {
	["__Test"] = function(Player, Argument, Data)
		return {
			Success = true,
			Result = {
				__GAtype = "__Test",
				Call = function(Callback, Index, Arguments)
					for i, Value in ipairs({"A", "B", "C"}) do
						Callback(Value)
					end
				end
			},
		}
	end,
	
	["Player"] = function(Player, Argument: string)
		if tonumber(Argument) then
			Argument = tonumber(Argument)
			local Player = Players:GetPlayerByUserId(Argument)
			
			if Player then
				return {
					Success = true,
					Result = Player,
				}
			end
			
			return {
				Success = true,
				Result = Argument,
			}
		end
		
		if table.find({"me", "self"}, Argument:lower()) then
			return {
				Success = true,
				Result = Player,
			}
		end
		
		local PlayerList = Players:GetPlayers()
		if Argument:lower() == "random" then
			local RandomPlayer = PlayerList[math.random(1, #PlayerList)]
			return {
				Success = true,
				Result = RandomPlayer
			}
		end
		
		if table.find({"everyone", "everybody", "all"}, Argument:lower()) then
			return {
				Success = true,
				Result = {
					__GAtype = "Player",
					Call = function(Callback, Index, Arguments)
						for i, player in ipairs(Players:GetPlayers()) do
							Callback(player)
						end
					end
				},
			}
		end
		
		if table.find({"other", "rest"}, Argument:lower()) then
			local Table = {}
			for i, player in ipairs(Players:GetPlayers()) do
				if Player.UserId == player.UserId then
					continue
				end
				
				table.insert(Table, player)
			end

			return {
				Success = true,
				Result = {
					__GAtype = "Player",
					Call = function(Callback, Index, Arguments)
						for i, player in ipairs(Table) do
							Callback(player)
						end
					end
				},
			}
		end
		
		for i, player in ipairs(PlayerList) do
			if not table.find({player.Name:lower():sub(1, #Argument), player.DisplayName:lower():sub(1, #Argument)}, Argument) then
				continue
			end
			
			return {
				Success = true,
				Result = player,
			}
		end
		
		return {
			Success = false,
			Result = `No player has been found by name '<font color="#ffbfaa">{Argument}</font>'.`,
		}
	end,
	
	["Tool"] = function(Player, Argument)
		warn(`[GAdmin Arguments]: Argument type 'Tool' is W.I.P.`)
		return {
			Success = false,
			Result = "Argument type 'Tool' is W.I.P."
		}
	end,
	
	["Object"] = function(Player, Argument: string, Data)
		local Specifics = Data.Specifics
		local Multiple = Specifics.Multiple
		
		local RawServices = Specifics.Services or {"Workspace", "ReplicatedStorage"}
		local Classes = Specifics.Classes or {"any"}
		local Properties = Specifics.Properties or {}
		
		local Blacklist = Specifics.Blacklist or {}
		local Whitelist = Specifics.Whitelist
		
		local Tags = Specifics.Tags or {}
		local Objects = {}
		
		local Services = {}
		if type(Specifics.Services) == "function" then
			Services = Specifics.Services(Player, Argument, Data)
		else
			for i, RawService in ipairs(RawServices) do
				local Service = game:FindService(RawService)
				if not Service then
					continue
				end
				
				table.insert(Services, Service)
			end
		end
		
		for i, Tag in ipairs(Tags) do
			if not table.find(Tag.Alias, Argument:lower()) then
				continue
			end
			
			for i, Service in ipairs(Services) do
				for i, Object in ipairs(Service:GetDescendants()) do
					--== Check class, blacklist, whitelist.
					if (not table.find(Classes, "any") and not table.find(Classes, Object.ClassName)) or table.find(Blacklist, Object) or table.find(Blacklist, Object.Name) or (Whitelist and not table.find(Whitelist, Object) and not table.find(Whitelist, Object.Name)) then
						continue
					end
					
					--== Check properties.
					local PropertyConflict = not HasProperties(Object, Properties)
					if PropertyConflict then
						continue
					end
					
					table.insert(Objects, Object)
				end
			end
			
			local Response = Tag.Call(Objects, Specifics)
			return {
				Success = #Response > 0,
				Result = #Response > 0 and {
					__GAtype = "Object",
					Call = function(Callback, Index, Arguments)
						for i, Object in ipairs(Response) do
							Callback(Object)
						end
					end,
				} or `No object has been found by argument '<font color="#ffbfaa">{Argument}</font>'`,
			}
		end
		
		for i, Service in ipairs(Services) do
			for i, Object in ipairs(Service:GetDescendants()) do
				--== Check class, blacklist, whitelist.
				if (not table.find(Classes, "any") and not table.find(Classes, Object.ClassName)) or table.find(Blacklist, Object) or table.find(Blacklist, Object.Name) or (Whitelist and not table.find(Whitelist, Object) and not table.find(Whitelist, Object.Name)) then
					continue
				end
				
				--== Check name.
				if Argument:lower() ~= Object.Name:sub(1, #Argument):lower() then
					continue
				end
				
				--== Check properties.
				local PropertyConflict = not HasProperties(Object, Properties)
				if PropertyConflict then
					continue
				end
				
				table.insert(Objects, Object)
			end
		end
		
		if Multiple then
			return {
				Success = true,
				Result = {
					__GAtype = "Object",
					Call = function(Callback, Index, Arguments)
						if #Objects <= 0 then
							Callback()
							return
						end
						
						for i, Object in ipairs(Objects) do
							Callback(Object)
						end
					end,
				}
			}
		end
		
		local Object = Objects[1]
		return Object and {
			Success = Object ~= nil,
			Result = {
				__GAtype = "Object",
				Unpack = function()
					return Object
				end,
			}
		} or `No object has been found by argument '<font color="#ffbfaa">{Argument}</font>'`
	end,
	
	["Rank"] = function(Player, Argument)
		local Rank = RankService:Find(tonumber(Argument) or Argument)
		if Rank then
			Rank.__GAtype = "Rank"
		end
		
		return {
			Success = Rank ~= nil,
			Result = Rank or `No rank has been found by argument '<font color="#ffbfaa">{Argument}</font>'`
		}
	end,
	
	["string"] = function(Player, Argument)
		return {
			Success = true,
			Result = tostring(Argument),
		}
	end,
	
	["number"] = function(Player, Argument)
		local Numbered = tonumber(Argument, 10)
		return {
			Success = Numbered ~= nil,
			Result = Numbered or `Unable to convert argument '<font color="#ffbfaa">{Argument}</font>' into a number.`,
		}
	end,
	
	["boolean"] = function(Player, Argument)
		local IsTrue = Argument:lower() == "true"
		local IsFalse = Argument:lower() == "false"
		local IsBoolean = IsTrue or IsFalse
		
		local Boolean
		if IsTrue then
			Boolean = true
		elseif IsFalse then
			Boolean = false
		end
		
		return {
			Success = IsBoolean,
			Result = Boolean or `<font color="#ffbfaa">true</font> or <font color="#ffbfaa">false</font> excepted, got '<font color="#ffbfaa">{Argument}</font>'.`,
		}
	end,
}