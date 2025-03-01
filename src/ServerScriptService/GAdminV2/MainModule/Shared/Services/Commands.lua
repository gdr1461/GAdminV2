--== << Services >>

local RunService = game:GetService("RunService")
local Shared = script:FindFirstAncestor("Shared")
local Types = require(Shared.Types)

local CommandsFolder = Shared.Commands
local GetSideServices = require(Shared.Services.Core.GetSideServices)

local RankService = require(Shared.Services.Rank)
local Side = game.Players.LocalPlayer == nil and "Server" or "Client"

local Remote = require(Shared.Services.Remote)
local FlagsTable = Side == "Server" and require(_G.GAdmin.Path.Server.Services.Parser.Flags) or nil

local RawEnums = GetSideServices:GetEnums(Side)
local Enums = GetSideServices:Require(RawEnums)

--==

local Proxy = newproxy(true)
local Commands: Types.CommandsService = getmetatable(Proxy)

Commands.__type = "GAdmin Commands"
Commands.__metatable = "[GAdmin Commands]: Metatable methods are restricted."

Commands.Commands = {}
Commands.Length = 0

function Commands:__tostring()
	return self.__type
end

function Commands:__index(Key)
	return Commands[Key]
end

function Commands:__newindex(Key, Value)
	Commands[Key] = Value
end

--[[
	Reloads commands list.
]]
function Commands:Reload()
	self.Commands = {}
	self.Length = 0
	
	for i, Module in ipairs(CommandsFolder:GetChildren()) do
		if not Module:IsA("ModuleScript") then
			warn(`[{self.__type}]: Expected '{Module.Name}' to be ModuleScript, got {Module.ClassName}.`)
			continue
		end
		
		local Command = require(Module)
		self:Load(Command, i)
	end
end

function Commands:LoadFolder(Folder)
	for i, Module in ipairs(Folder:GetChildren()) do
		if not Module:IsA("ModuleScript") then
			warn(`[{self.__type}]: Expected '{Module.Name}' to be ModuleScript, got {Module.ClassName}.`)
			continue
		end

		local Command = require(Module)
		Command.Order = nil
		self:Load(Command)
	end
end

--[[
	Loads command from command data.
]]
function Commands:Load(Command, Index)
	local OpposideSide = Side == "Server" and "Client" or "Server"
	local HasClient = Side == "Server" and Command.Client and Command.Client.Run
	Command[OpposideSide] = {}
	
	if Command.Internal and not RunService:IsStudio() then
		return
	end

	--== Default values.
	Command.Name = Command.Name or `Cmd-{self.Length + 1}`
	Command.Description = Command.Description or "N/A"
	
	Command.Rank = Command.Rank or 0
	Command.Alias = Command.Alias or {}
	Command.Order = Command.Order or Index or self.Length + 1
	Command.Arguments = Command.Arguments or {}
	
	Command[Side] = Command[Side] or {}
	Command.HasClient = HasClient
	
	if Command.Fluid == nil then
		Command.Fluid = false
	end
	
	if Command.Internal then
		Command.Tag = {
			Name = "Studio Only",
			Color = Color3.new(1, 1, 0)
		}
	end
	--==

	if Command.Order <= 0 then
		return
	end

	if not RankService:Find(Command.Rank) then
		warn(`[{self.__type}]: {Command.Name} :: Rank '{Command.Rank}' is invalid.`)
		Command.Rank = 0
	end

	if Side == "Server" then
		Command.Server.Update = function()
			self:Update(Command.Name)
		end
		
		for Index, Argument in ipairs(Command.Arguments) do
			Argument.Flags = Argument.Flags or {}
			Argument.Specifics = Argument.Specifics or {}
			
			if Argument.Specifics.AutoFill then
				for i, CustomFill in ipairs(Argument.Specifics.AutoFill) do
					if table.find({"function", "table"}, type(CustomFill)) then
						continue
					end
					
					warn(`[{self.__type}]: AutoFill list must contain only functions and tables in the command '{Command.Name}'.`)
				end
			end

			for i, ArgumentFlag in ipairs(Argument.Flags) do
				local Flag = FlagsTable[ArgumentFlag]
				if not Flag then
					task.delay(1, function()
						warn(`[{self.__type}]: Flag {ArgumentFlag} :: Flag is invalid.`)
					end)

					continue
				end

				if not Flag.Requirements then
					continue
				end

				local Request = Flag.Requirements(Command, {
					Index = Index,
					Argument = Argument
				}, Command.Arguments)

				if Request.Success then
					continue
				end

				task.delay(1, function()
					warn(`[{self.__type}]: Flag {ArgumentFlag} :: {Request.Response}`)
				end)
			end
		end
	end

	if Command[Side].Get then
		local Arguments = Command[Side]:Get(Enums)
		for i, v in pairs(Arguments) do
			if Command[Side][i] then
				warn(`[{self.__type}]: Variable '{i}' already exist in {Side} of command '{Command.Name}'.`)
				continue
			end

			Command[Side][i] = v
		end
	end
	
	self.Commands[Command.Name] = Command
	self.Length += 1
end

--[[
	Returns Dictionary table of rank and commands of given ranks.
]]
function Commands:GetRank(RankOrRanks)
	local Ranks = type(RankOrRanks) == "table" and RankOrRanks or {RankOrRanks}
	local RankCommands = {}
	
	local List = self:GetList()
	for i, Command in ipairs(List) do
		local Rank = RankService:Find(Command.Rank).Name
		if not table.find(Ranks, Rank) then
			continue
		end

		RankCommands[Rank] = RankCommands[Rank] or {}
		table.insert(RankCommands[Rank], Command)
	end
	
	return RankCommands
end

--[[
	Updates command arguments for client.
]]
function Commands:Update(CommandName)
	if Side ~= "Server" then
		warn(`[{self.__type}]: Command could only be updated from server.`)
		return
	end
	
	local Command = self:Find(CommandName)
	if not Command then
		warn(`[{self.__type}]: Unable to find command with name '{CommandName}'.`)
		return
	end
	
	if not Command.Fluid then
		warn(`[{self.__type}]: {Command.Name} :: Only fluid commands can be updated in real time.`)
		return
	end
	
	Remote:FireAll("FluidCommand", Command.Name, Command.Arguments)
end

--[[
	Returns array table that contains command datas in order.
]]
function Commands:GetList()
	local Commands = {}
	for Name, Command in pairs(self.Commands) do
		table.insert(Commands, Command)
	end
	
	table.sort(Commands, function(Command1, Command2)
		return Command1.Order < Command2.Order
	end)
	
	return Commands
end

--[[
	Returns command data from command name.
]]
function Commands:Find(Name: string, UnReliable)
	if self.Commands[Name] then
		return self.Commands[Name]
	end
	
	if UnReliable then
		for CommandName, Command in pairs(self.Commands) do
			local NotFound = (Name:lower() ~= CommandName:sub(1, #Name):lower()) or (not Command.Fluid and Name ~= CommandName:sub(1, #Name))
			if NotFound then
				if Command.Alias then
					for i, Alias in ipairs(Command.Alias) do
						if (Name:lower() ~= Alias:sub(1, #Name):lower()) or (not Command.Fluid and Name ~= Alias:sub(1, #Name)) then
							continue
						end

						return Command
					end
				end

				continue
			end

			return Command
		end
		
		return
	end
	
	for CommandName, Command in pairs(self.Commands) do
		local NotFound = (Name:lower() ~= CommandName:lower()) or (not Command.Fluid and Name ~= CommandName)
		if NotFound then
			if Command.Alias then
				for i, Alias in ipairs(Command.Alias) do
					if (Name:lower() ~= Alias:lower()) or (not Command.Fluid and Name ~= Alias) then
						continue
					end
					
					return Command
				end
			end
			
			continue
		end
		
		return Command
	end
end

return Proxy :: Types.CommandsService