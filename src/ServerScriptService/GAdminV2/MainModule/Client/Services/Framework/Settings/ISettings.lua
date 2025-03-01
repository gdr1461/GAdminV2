local Proxy = newproxy(true)
local Settings = getmetatable(Proxy)

Settings.__type = "GAdmin ISettings"
Settings.__metatable = "[GAdmin ISettings]: Metatable methods are restricted."

function Settings:__index(Key)
	if Key == "Settings" then
		return
	end
	
	return Settings[Key]
end

function Settings:Set(Setting)
	if type(Setting) ~= "table" then
		warn(`[{self.__type}]: Setting must be a type of table.`)
		return
	end
	
	if not utf8.len(Setting.Name) then
		warn(`[{self.__type}]: Setting must have Name string key.`)
		return
	end
	
	if Settings.Settings:Find(Setting.Name) then
		warn(`[{self.__type}]: Setting with name '{Setting.Name}' already exists.`)
		return
	end
	
	if Setting.Description and not utf8.len(Setting.Description) then
		warn(`[{self.__type}]: Setting description must be a string.`)
		return
	end
	
	if not utf8.len(Setting.Type) then
		warn(`[{self.__type}]: Setting must have Type string key.`)
		return
	end
	
	if not Settings.Settings.Inputs[Setting.Type] then
		warn(`[{self.__type}]: Specified setting type is invalid.`)
		return
	end
	
	if type(Setting.Callback) ~= "function" then
		warn(`[{self.__type}]: Setting must have Callback function key.`)
		return
	end
	
	if Setting.LoadData ~= nil and type(Setting.LoadData) ~= "function" then
		warn(`[{self.__type}]: Setting LoadData handler must be a function.`)
		return
	end
	
	if Setting.SaveData ~= nil and type(Setting.SaveData) ~= "function" then
		warn(`[{self.__type}]: Setting SaveData handler must be a function.`)
		return
	end
	
	return Settings.Settings:Add(Setting)
end

function Settings:Reload()
	return Settings.Settings:Reload()
end

return {
	Load = function(self, SettingHandler)
		Settings.Settings = SettingHandler
		return Proxy
	end,
}