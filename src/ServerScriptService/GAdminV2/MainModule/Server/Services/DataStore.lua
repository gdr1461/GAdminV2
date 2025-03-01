--== << Services >>
local DataStoreService = game:GetService("DataStoreService")
local Main = script:FindFirstAncestor("Server")

local Data = require(Main.Data)
local Configuration = Data.Settings

local MainSettings = require(Configuration.Main)
local Settings = require(Configuration.DataStore)
--==

local Proxy = newproxy(true)
local DataStore = getmetatable(Proxy)

DataStore.__type = "GAdmin DataStore"
DataStore.__metatable = "[GAdmin DataStore]: Metatable methods are restricted."

DataStore.SystemStore = DataStoreService:GetDataStore(Settings.Stores.System)
DataStore.PlayerStore = DataStoreService:GetDataStore(Settings.Stores.Player)
DataStore.CodeStore = DataStoreService:GetDataStore(Settings.Stores.Code)

function DataStore:__tostring()
	return self.__type
end

function DataStore:__index(Key)
	return DataStore[Key]
end

function DataStore:Load(StoreName, Key)
	local Store = self[`{StoreName}Store`]
	if not Store then
		warn(`[{self.__type}]: Store with name '{StoreName}Store' is invalid.`)
		return
	end
	
	local Success, Response
	local Attempts = 0

	repeat
		Success, Response = pcall(function()
			return Store:GetAsync(Key)
		end)
		
		if not Success then
			if Settings.Output then
				warn(`[{self.__type}]: Failed to load key '{Key}' of {StoreName} :: {Response}`)
			end
			
			Attempts += 1
			task.wait(Settings.RetryOn)
		end
	until Success or Attempts >= Settings.Stores.Attempts[Store]
	
	if Success then
		local Template = StoreName == "System" and Data.DataStores[StoreName][Key] or Data.DataStores[StoreName]
		Response = Response or Template
		
		for i, v in pairs(Template) do
			if Response[i] ~= nil then
				continue
			end
			
			Response[i] = v
		end
	end
	
	return Success, Response
end

function DataStore:Save(StoreName, Key, Data)
	local Store = self[`{StoreName}Store`]
	if not Store then
		warn(`[{self.__type}]: Store with name '{StoreName}Store' is invalid.`)
		return
	end
	
	local Success, Response
	local Attempts = 0

	repeat
		Success, Response = pcall(function()
			Store:SetAsync(Key, Data)
		end)

		if not Success then
			if Settings.Output then
				warn(`[{self.__type}]: Failed to save key '{Key}' of {StoreName} :: {Response}`)
			end

			Attempts += 1
			task.wait(Settings.RetryOn)
		end
	until Success or Attempts >= Settings.Stores.Attempts[Store]

	return Success
end

return Proxy