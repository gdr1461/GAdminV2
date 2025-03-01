--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Commands = require(Main.Shared.Services.Commands)

local Cache = require(Main.Client.Services.Framework.Cache)
local ArgumentTable = require(script.Arguments)

function CopyTable(Table)
	local Copy = {}
	for i, v in pairs(Table) do
		if type(v) == "table" then
			Copy[i] = CopyTable(v)
			continue
		end

		Copy[i] = v
	end

	return Copy
end
--==

local AutoFill = {}

function AutoFill:Fill(String, Cursor, Word)
	local Prefix = Cache.Session.Prefix
	local Cut = String:sub(1, Cursor)
	
	local Words = Cut:split(" ")
	local Difference = 0
	
	for i, Symbol in ipairs(Word:split("")) do
		if Words[#Words][i] then
			continue
		end
		
		Difference += 1
	end
	
	Cursor += Difference
	Words[#Words] = Word

	return table.concat(Words, " "), Cursor
end

function AutoFill:Get(String, CustomCommand, ArgumentIndex)
	local List = Commands:GetList()
	local Prefix = Cache.Session.Prefix
	
	local Branches = String:split(Prefix)
	local Branch = Branches[#Branches]
	
	local Words = Branch:split(" ")
	local CommandName = Words[1]:gsub(Prefix, "")
	
	local Index = #Words
	local Word = ArgumentIndex and Branch or Words[Index]:gsub(Prefix, "")
	local Command = CustomCommand or Commands:Find(CommandName, true)
	
	if not Command or Word:gsub("%s+", "") == "" then
		return {}
	end
	
	local IsCommand = CommandName == Word and not CustomCommand
	if IsCommand then
		local ToSearch = {}
		for i, Command in ipairs(List) do
			local Search = table.clone(Command.Alias)
			table.insert(Search, Command.Name)
			
			table.insert(ToSearch, {
				Frame = Command.Name,
				Search = Search
			})
		end
		
		local Results = self:Search(ToSearch, Word)
		local Fills = {}
		
		for i, Result in ipairs(Results) do
			local Command = Commands:Find(Result.Frame)
			local Arguments = {}
			
			for i, Argument in ipairs(Command.Arguments) do
				local Name = Argument.Name or Argument.Types[1]
				table.insert(Arguments, `[{Name}]`)
			end
		
			table.insert(Fills, {
				Display = `{Prefix}{Result.Frame} {table.concat(Arguments, " ")}`,
				ToFill = `{Prefix}{Result.Frame}`
			})
		end
		
		return Fills
	end
	
	local Fills = {}
	if ArgumentIndex then
		local Argument = Command.Arguments[ArgumentIndex]
		return self:GetArgumentFill(Word, Argument, Command)
	end
	
	for i, Argument in ipairs(Command.Arguments) do
		if Index - 1 ~= i and not CustomCommand then
			continue
		end
		
		local ArgumentFill = self:GetArgumentFill(Word, Argument, Command)
		Fills = ArgumentFill
	end
	
	return Fills
end

function AutoFill:Search(Table, String: string)
	local IsEmptyString = String:gsub("%s+", "") == ""
	local Items = {}

	local FirstSearch = {}
	local SecondSearch = {}
	
	for i, Item in ipairs(Table) do
		local IsSecondSearch = false
		local IsValid
		
		for i, Searchable in ipairs(Item.Search) do
			Searchable = type(Searchable) == "string" and Searchable or tostring(Searchable)
			if Searchable:lower():sub(1, #String) ~= String:lower() and not IsEmptyString then
				if Searchable:lower():find(String:lower()) then
					local ItemCopy = CopyTable(Item)
					ItemCopy.Searched = IsValid

					IsSecondSearch = true
					table.insert(SecondSearch, ItemCopy)
					continue
				end

				continue
			end

			IsValid = Searchable
			break
		end

		if not IsValid or IsSecondSearch then
			continue
		end

		local ItemCopy = CopyTable(Item)
		ItemCopy.Searched = IsValid
		table.insert(FirstSearch, ItemCopy)
	end

	Items = FirstSearch
	for i, v in ipairs(SecondSearch) do
		local Invalid = false
		for i, Item in ipairs(FirstSearch) do
			if Item.Frame ~= v.Frame then
				continue
			end

			Invalid = true
			table.insert(Items, Item)
			break
		end

		if Invalid then
			continue
		end

		table.insert(Items, v)
	end

	return Items, IsEmptyString
end

function AutoFill:GetArgumentFill(Word: string, Argument, Command)
	local Fills = {}
	for i, ArgumentType in ipairs(Argument.Types) do
		if not ArgumentTable[ArgumentType] then
			continue
		end

		local ArgumentFill = ArgumentTable[ArgumentType](Word, Argument)
		if #ArgumentFill <= 0 then
			continue
		end

		Fills = ArgumentFill
		break
	end
	
	if Argument.Specifics.AutoFill then
		for i, CustomFill in ipairs(Argument.Specifics.AutoFill) do
			if type(CustomFill) == "table" then
				local NewFill = {}
				for i, String in ipairs(CustomFill) do
					if String:sub(1, #Word):lower() ~= Word:lower() then
						continue
					end

					table.insert(NewFill, String)
				end
				
				if Argument.Specifics.AutoFillOverride then
					Fills = NewFill
					break
				end

				for i, v in ipairs(NewFill) do
					table.insert(Fills, v)
				end

				continue
			end
			
			local ArgumentFill = CustomFill(Command, Argument, Word)
			if #ArgumentFill <= 0 then
				continue
			end
			
			if Argument.Specifics.AutoFillOverride then
				Fills = ArgumentFill
				break
			end

			for i, v in ipairs(ArgumentFill) do
				table.insert(Fills, v)
			end
		end
	end
	
	return Fills
end

return AutoFill