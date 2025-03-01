--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")
local RankService = require(Main.Shared.Services.Rank)
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
	["Player"] = function(Word: string)
		local Fills = {}
		local Table = Players:GetPlayers()
		
		table.insert(Table, {Name = "me"})
		table.insert(Table, {Name = "other"})
		table.insert(Table, {Name = "all"})
		table.insert(Table, {Name = "random"})
		
		for i, player in ipairs(Table) do
			if player.Name == Word then
				table.insert(Fills, player.Name)
				break
			end
			
			if player.Name:lower():sub(1, #Word) ~= Word:lower() then
				continue
			end
			
			table.insert(Fills, player.Name)
		end
		
		return Fills
	end,
	
	["Object"] = function(Word: string, Data)
		local Specifics = Data.Specifics
		local Multiple = Specifics.Multiple

		local RawServices = Specifics.Services or {"Workspace", "ReplicatedStorage"}
		local Classes = Specifics.Classes or {"any"}
		local Properties = Specifics.Properties or {}

		local Blacklist = Specifics.Blacklist or {}
		local Whitelist = Specifics.Whitelist

		local Tags = Specifics.Tags or {}
		local Objects = {}
		
		for i, Tag in ipairs(Tags) do
			local InRange = false
			for i, Name in ipairs(Tag.Alias) do
				if Word:lower() ~= Name:sub(1, #Word):lower() then
					continue
				end
				
				InRange = true
				break
			end
			
			if not InRange then
				continue
			end

			table.insert(Objects, Tag.Alias[1])
		end
		
		local Services = {}
		if type(Specifics.Services) == "function" then
			Services = Specifics.Services(Players.LocalPlayer, Word, Data)
		else
			for i, RawService in ipairs(RawServices) do
				local Service = game:FindService(RawService)
				if not Service then
					continue
				end

				table.insert(Services, Service)
			end
		end
		
		for i, Service in ipairs(Services) do
			for i, Object in ipairs(Service:GetDescendants()) do
				--== Check class, blacklist, whitelist.
				local InBlacklist = table.find(Blacklist, Object) or table.find(Blacklist, Object.Name)
				if (not table.find(Classes, "any") and not table.find(Classes, Object.ClassName)) or InBlacklist or (Whitelist and not table.find(Whitelist, Object) and not table.find(Whitelist, Object.Name)) then
					continue
				end

				--== Check name.
				if Word:lower() ~= Object.Name:sub(1, #Word):lower() then
					continue
				end

				--== Check properties.
				local PropertyConflict = not HasProperties(Object, Properties)
				if PropertyConflict then
					continue
				end
				
				local Path = Object:GetFullName()
				local Index = math.max(#Path - #Object.Name, 1)
				
				local Start, End = Path:find(Object.Name, Index, true)
				local RestPath = Path:sub(1, Start - 1)
				
				local HasSpaces = Object.Name:find(" ", nil, true)
				local Replacement = HasSpaces and `["{Object.Name}"]` or Object.Name
				
				local PathIndex = HasSpaces and #RestPath - 1 or #RestPath
				local FullName = `{RestPath:sub(1, PathIndex)}{Replacement}`
				
				table.insert(Objects, {
					Display = `[{Object.ClassName}] {Object.Name} <font color="#a9a9a9" size="11">{FullName}</font>`,
					ToFill = Object.Name
				})
			end
		end

		return Objects
	end,
	
	["Rank"] = function(Word: string)
		local Fills = {}
		local Ranks = RankService:GetArray()
		
		for i, RankName in ipairs(Ranks) do
			if RankName == Word then
				return {RankName}
			end
			
			if RankName:lower():sub(1, #Word) ~= Word:lower() then
				continue
			end
			
			table.insert(Fills, RankName)
		end
		
		return Fills
	end,
	
	["boolean"] = function(Word: string)
		local Correct = {"true", "false"}
		local Fills = {}
		
		for i, CorrectWord in ipairs(Correct) do
			if CorrectWord ~= Word and CorrectWord:sub(1, #Word) ~= Word:lower() then
				continue
			end
			
			table.insert(Fills, CorrectWord)
		end
		
		return Fills
	end,
}