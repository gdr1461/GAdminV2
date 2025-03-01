--== << Services >>

local RunService = game:GetService("RunService")
local Data = require(script:FindFirstAncestor("Server").Data)

local Shared = Data.Shared
local Configuration = Data.Settings

local Types = require(Data.Shared.Types)
local MainSettings = require(Configuration.Main)

local Commands = require(Data.Shared.Services.Commands)
local API = require(Data.Server.Services.API)
local Remote = require(Data.Shared.Services.Remote)

local Popup = require(Shared.Services.Popup)
local Rank = require(Shared.Services.Rank)

local ArgumentsTable = require(script.Arguments)
local FlagsTable = require(script.Flags)

--==

local Proxy = newproxy(true)
local Parser: Types.ParseService = getmetatable(Proxy)

Parser.__type = "GAdmin Parser"
Parser.__metatable = "[GAdmin Parser]: Metatable methods are restricted."

function Parser:__tostring()
	return self.__type
end

function Parser:__index(Key)
	return Parser[Key]
end

--[[
	Calls command.
]]
function Parser:Call(Branch, Protected)
	if Branch.Failed then
		return false, "Branch failed."
	end
	
	local CommandName = Branch.Command
	local Command = Commands:Find(CommandName)
	
	if not Command then
		warn(`[{self.__type}]: Command with name '{CommandName}' is invalid.`)
		return false, `Command with name '{CommandName}' is invalid.`
	end
	
	if Command.Rank == "Internal" and not Rank:IsInternal(Branch.Caller.UserId) then
		return false, `Caller '{Branch.Caller}' is not internal.`
	end
	
	local function Run(Arguments)
		Arguments = Arguments or Branch.Arguments
		local RawArguments = {}
		
		local Blocked = false
		for Index, Argument in ipairs(Arguments) do
			--== Unpacks argument from table down to its raw form.
			if type(Argument) == "table" and Argument.Unpack then
				Arguments[Index] = Argument.Unpack()
				continue
			end
			
			--[[
			
				Calling values inside of argument.
				@Example:
				
				Argument = {"A", "B", "C"}
				
				Calling..
				
				Call #1 - A,
				
				Call #2 - B,
				
				Call #3 - C.
			
			]]
			
			if type(Argument) == "table" and Argument.Call then
				Blocked = true
				Argument.Call(function(Value)
					local Copy = table.clone(Arguments)
					Copy[Index] = Value
					Run(Copy)
				end, Index, table.clone(Arguments))
				
				continue
			end
		end
		
		if Blocked then
			return
		end
		
		--== Run on server.
		if Command.Server and Command.Server.Run then
			Command.Server:Run(Branch.Caller, Arguments)
		end
		
		--== Run on client.
		Branch.Client = Branch.Client or Branch.Caller
		if Command.HasClient then
			Remote:Fire("RunCommandClient", Branch.Client, Branch.Command, Arguments)
		end
		
		local Prefix = API:GetPrefix(Branch.Caller)
		local Log = {
			UserId = Branch.Caller.UserId,
			Command = Branch.Command,
			Arguments = Arguments,
			RawArguments = Branch.RawArguments,
			Time = DateTime.now().UnixTimestamp,
			Message = `{Prefix}{Branch.Command} {table.concat(Branch.RawArguments, " ")}`,
		}
		
		table.insert(Data.Logs, Log)
	end
	
	if Protected then
		local Success, Response = pcall(Run)
		if not Success then
			warn(`[GAdmin Parser]: Error occurred in command '{Command.Name}' :: '{Response}'`)
		end
		
		return Success, Response
	end
	
	coroutine.wrap(Run)()
end

--[[
	Returns table that contains branch of commands and their arguments from given string.
]]
function Parser:Parse(Caller, Message, CheckPermissions)
	local Prefix = API:GetPrefix(Caller)
	if not Message:find(Prefix) then
		return {}
	end
	
	local MessageCommands = Message:split(Prefix)
	local Branches = {}
	
	for i, CommandMessage in ipairs(MessageCommands) do
		if CommandMessage:gsub("%s+", "") == "" then
			continue
		end
		
		local SplittedMessage = CommandMessage:split(" ")
		local Command
		local RawArguments = {}
		
		for i, String in ipairs(SplittedMessage) do
			if String:gsub("%s+", "") == "" then
				continue
			end
			
			-- Getting command name from branch.
			if not Command then
				local FormattedString = String:gsub(Prefix, "")
				local Exists = Commands:Find(FormattedString)
				
				if not Exists then
					Popup:New({
						Type = "Error",
						Text = `Command '{FormattedString}' is invalid.`,
						Player = Caller
					})
					
					return {}
				end
				
				if CheckPermissions and Exists.Rank > API:GetRank(Caller).Rank then
					Popup:New({
						Type = "Error",
						Text = `You must be rank '{Rank:Find(Exists.Rank).Name}' or higher to use this command.`,
						Player = Caller
					})
					
					return {}
				end
				
				Command = FormattedString
				continue
			end
			
			table.insert(RawArguments, String)
		end
		
		local Branch = {
			Caller = Caller,
			Command = Command,
			RawArguments = RawArguments,
		}
		
		local Arguments = self:Transform(Branch, RawArguments)
		Branch.Arguments = Arguments
		Branch.Client = Branch.Client or Caller
		
		if Arguments.Failed then
			Branch = {Failed = true}
		end
		
		table.insert(Branches, Branch)
	end
	
	return Branches
end

--[[
	Returns table that contains formatted arguments from given array table of strings.
]]
function Parser:Transform(Branch, RawArguments)
	local Command = Commands:Find(Branch.Command)
	local Arguments = {}
	
	for FlagName, Flag in pairs(FlagsTable) do
		if Flag.Return ~= "Define" then
			continue
		end
		
		local Response = Flag.Method(self, Branch, {
			Raw = RawArguments,
			Default = Command.Arguments,
		})

		if not Response or not Response.Success then
			continue
		end

		RawArguments = Response.Request
	end
	
	-- Turn raw argument strings into ready-to-use arguments.
	for i, Argument in ipairs(RawArguments) do
		local ArgumentData = Command.Arguments[i]
		if not ArgumentData then
			break
		end
		
		local Request = self:GetFlag(Branch, {
			Argument = Argument,
			Data = ArgumentData
		})

		if not Request.Success then
			Popup:New({
				Type = "Error",
				Text = Request.Response or "An unexpected error occurred.",
				Player = Branch.Caller
			})

			return {Failed = true}
		end
		
		if not Request.Response then
			Popup:New({
				Type = "Error",
				Text = `Unable to analyze argument '<font color="#ffbfaa">{Argument}</font>'.`,
				Player = Branch.Caller
			})
			
			return {Failed = true}
		end
		
		table.insert(Arguments, Request.Response)
		Branch.Client = Branch.Client or Request.Client
		
		--[[
		local Transformed = false
		for Type, Function in pairs(ArgumentsTable) do
			for i, ArgumentType in ipairs(ArgumentData.Types) do
				if Type:lower() ~= ArgumentType:lower() then
					continue
				end

				local Response = Function(Branch.Caller, Argument, ArgumentData)
				if not Response.Success then
					continue
				end

				local Success, Flag = self:CheckFlags(Branch.Caller, Response.Result, ArgumentData)
				if not Success then

				end

				table.insert(Arguments, Flag)
				Transformed = true
				break
			end

			if Transformed then
				break
			end
		end
		]]
	end
	
	return self:Validate(Command, Branch, Arguments, RawArguments)
end

--[[
	Validate and place every non-optional argument into it's place.
]]
function Parser:Validate(Command, Branch, Arguments, RawArguments)
	if Command.Rank <= -1 and not RunService:IsStudio() then
		Popup:New({
			Type = "Error",
			Text = `Command '<font color="#ffbfaa">{Command.Name}</font> can only be used inside of the studio.'`,
			Player = Branch.Caller,
		})
		
		return {Failed = true}
	end
	
	local ToValidate = {}
	local Validated = 0

	for i, ArgumentData in ipairs(Command.Arguments) do
		if table.find(ArgumentData.Flags, "Optional") then
			continue
		end

		table.insert(ToValidate, {
			Data = ArgumentData,
			Index = i
		})
	end

	for i, Argument in ipairs(Arguments) do
		local ArgumentData = Command.Arguments[i]
		if table.find(ArgumentData.Flags, "Optional") then
			continue
		end

		Validated += 1
	end

	--[[
		Repositioning arguments if optional ones is not defined.
		Example:
		
		@TEMPLATE: {PLAYER, STRING, NUMBER}
		@GIVEN: {PLAYER, NUMBER}
		@RESULT: {PLAYER, NIL, NUMBER}
	]]

	if #ToValidate <= Validated then
		return Arguments
	end
	
	local function Error(UnValidated)
		if not UnValidated then
			Popup:New({
				Type = "Error",
				Text = `Argument is not optional.`,
				Player = Branch.Caller
			})
			
			return {Failed = true}
		end
		
		Popup:New({
			Type = "Error",
			Text = `Argument '<font color="#ffbfaa">{UnValidated.Data.Name or UnValidated.Data.Types[1]}</font>' is not optional.`,
			Player = Branch.Caller
		})

		return {Failed = true}
	end
	
	-- Getting number of non-optional arguments not defined.
	for i = #ToValidate - Validated, 1, -1 do
		local UnValidated = ToValidate[i]  -- Current argument   --ToValidate[i + 1]
		if not UnValidated then
			return Error(UnValidated)
		end
		
		local Neighbour = Command.Arguments[UnValidated.Index - 1] -- Getting previous argument

		-- Neighbour doesn't exist or is not an optional argument
		if not Neighbour or not table.find(Neighbour.Flags, "Optional") then
			return Error(UnValidated)
		end

		local Request = self:GetFlag(Branch, {
			Argument = RawArguments[UnValidated.Index - 1],
			Data = UnValidated.Data
		})

		if not Request.Success or not Request.Response then
			return Error(UnValidated)
		end

		Arguments[UnValidated.Index + 1] = Request.Response
		Arguments[UnValidated.Index - 1] = nil
	end

	--local UnValidated = ToValidate[Validated + 1]
	--Popup:New({
	--	Type = "Error",
	--	Text = `Argument '{UnValidated}' is not optional.`,
	--	Player = Branch.Caller
	--})

	--return {Failed = true}
	return Arguments
end

--[[
	Returns flagged argument that can be given to the command itself.
]]
function Parser:GetFlag(Branch, Data)
	for Type, Function in pairs(ArgumentsTable) do
		for i, ArgumentType in ipairs(Data.Data.Types) do
			if Type:lower() ~= ArgumentType:lower() then
				continue
			end
			
			local Response = Function(Branch.Caller, Data.Argument, Data.Data)
			if not Response.Success then
				return {
					Success = false,
					Response = Response.Result
				}
			end
			
			local Success, Flag, Client = self:CheckFlags(Branch.Caller, Response.Result, Data.Data)
			if not Success then
				if #Data.Data.Types > 1 then
					continue
				end
				
				return {
					Success = false,
					Response = Flag,
				}
			end
			
			if not Flag then
				continue
			end
			
			return {
				Success = true,
				Response = Flag,
				Client = Client,
			}
		end
	end
	
	return {
		Success = true,
		Response = nil
	}
end

--[[
	Checks argument with given flag requirments.
]]
function Parser:CheckFlags(Caller, Argument, Data)
	Data.Flags = Data.Flags or {}
	Data.Rank = Data.Rank or 0
	
	-- Check player rank.
	local RankData = Rank:Find(Data.Rank)
	if not RankData then
		warn(`[{self.__type}]: Rank '{Data.Rank}' is invalid.`)
		return false, `Rank '{Data.Rank}' is invalid.`
	end

	local PlayerRank = API:GetRank(Caller)
	if RankData.Rank > PlayerRank.Rank then
		return false, `Your rank must be '{RankData.Name}' or higher.`
	end
	
	-- Flags
	local SideControl
	local ToReturn
	local IsOptional = table.find(Data.Flags, "Optional")

	local Name = Data.Name or Data.Type[1]
	for i, Flag in ipairs(Data.Flags) do
		if not FlagsTable[Flag] then
			warn(`[{self.__type}]: Argument flag '{Flag}' is invalid.`)
			return false, `Argument flag '{Flag}' is invalid.`
		end
		
		if FlagsTable[Flag].Return == "Define" then
			continue
		end
		
		if not table.find(FlagsTable[Flag].Type, "any") then
			local ValidType = false
			for i, Type in ipairs(FlagsTable[Flag].Type) do
				local IsInstance = typeof(Argument) == "Instance" and Argument:IsA(Type)
				local IsPlayer = IsInstance
				
				if not IsPlayer then
					local Success, Response = pcall(function()
						return game.Players:GetNameFromUserIdAsync(Argument)
					end)
					
					IsPlayer = Success and Response ~= nil
				end
				
				local IsType = Type == type(Argument)
				local IsTable = type(Argument) == "table" and Argument.__GAtype == Type
				
				local IsValid = IsType or IsTable or IsInstance or IsPlayer
				local IsNextArgument = IsOptional and not IsValid
				
				if IsNextArgument then
					return true, {
						__GAType = "Argument.Next",
						Value = Argument
					}
				end
				
				if not IsValid then
					continue
				end
				
				ValidType = true
				break
			end
			
			if not ValidType then
				return false, `Argument '{Name}' must be type of {table.concat(FlagsTable[Flag].Type, " / ")}.`
			end
		end
		
		local Success, Response = FlagsTable[Flag].Method(Caller, Argument, Data)
		if not Success then
			return false, Response or `Flag '{Flag}' is incorrect.`
		end
		
		if FlagsTable[Flag].Return == "SideControl" then
			if SideControl then
				warn(`[{self.__type}]: Argument can have only one side controlling flag. ([{Name}] - [{Flag}])`)
				return false, `Argument can have only one side controlling flag. ([{Name}] - [{Flag}])`
			end
			
			SideControl = Response
		end
		
		if FlagsTable[Flag].Return == "Response" then
			if ToReturn then
				warn(`[{self.__type}]: Argument can have only one responsive flag. ([{Name}] - [{Flag}])`)
				return false, `Argument can have only one responsive flag. ([{Name}] - [{Flag}])`
			end
			
			ToReturn = Response
		end
	end
	
	if not IsOptional and not Argument then
		return false, `Argument {Name} is not optional.`
	end
	
	if type(Argument) == "table" and Argument.__GAtype then
		Argument.__GAtype = nil
	end
	
	return true, ToReturn or Argument, SideControl
end

return Proxy :: Types.ParseService