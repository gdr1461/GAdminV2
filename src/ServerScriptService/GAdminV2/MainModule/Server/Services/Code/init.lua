--== << Services >>
local Main = script:FindFirstAncestor("Server")
local Data = require(Main.Data)

local DataStore = require(Main.Services.DataStore)
local Settings = require(Data.Settings.Main)
local Template = require(script.Template)
--==

local Proxy = newproxy(true)
local Code = getmetatable(Proxy)

Code.__type = "GAdmin CodeSaver"
Code.__metatable = "[GAdmin CodeSaver]: Metatable methods are restricted."

function Code:__tostring()
	return self.__type
end

function Code:__index(Key)
	return Code[Key]
end

function Code:Save(player, Id, Code)
	local Success, Response = self:IsValid(player, Id, Code)
	if not Success then
		return false, Response
	end
	
	local Success, PlayerData = DataStore:Load("Code", player.UserId)
	if not Success then
		return false, PlayerData
	end
	
	PlayerData[Id] = Code
	return DataStore:Save("Code", player.UserId, PlayerData)
end

function Code:Load(player, Id)
	local Success, PlayerData = DataStore:Load("Code", player.UserId)
	if not Success then
		return false, PlayerData
	end
	
	return true, PlayerData
end

function Code:GetId(Id)
	return Template[Id]
end

function Code:IsValid(player, Id, Code)
	if not Settings.ExecutorEnabled then
		return false, "Executor disabled."
	end
	
	if type(Id) ~= "string" then
		return false, "Id must be a type of string."
	end
	
	if not utf8.len(Id) then
		return false, "Id must be valid utf8 character."
	end
	
	if not Template[Id] then
		return false, `Id '{Id}' is invalid.`
	end
	
	if type(Code) ~= "string" then
		return false, "Code must be a type of string."
	end

	if not utf8.len(Code) then
		return false, "Code must be valid utf8 character."
	end
	
	local CodeLengthLimit = Template[Id].Length or Settings.CodeLengthLimit
	if #Code > CodeLengthLimit then
		return false, `Code length is over the limit. ({CodeLengthLimit})`
	end
	
	return true
end

return Proxy