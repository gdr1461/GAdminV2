local Proxy = newproxy(true)
local Core = getmetatable(Proxy)

Core.__type = "GAdmin Core"
Core.__metatable = "[GAdmin Core]: Metatable methods are restricted."

function Core:__tostring()
	return self.__type
end

function Core:__index(Key)
	return Core[Key]
end

function Core:__newindex(Key, Value)
	Core[Key] = Value
end

for i, Module in ipairs(script:GetChildren()) do
	if not Module:IsA("ModuleScript") then
		continue
	end
	
	local Success, Response = pcall(function()
		Core[Module.Name] = require(Module)
		local IsTable = type(Core[Module.Name]) == "table"
		
		if IsTable and Core[Module.Name].Incompatible then
			Core[Module.Name] = nil
			return
		end
		
		if not IsTable then
			return
		end
		
		Core[Module.Name].Core = Core
	end)
	
	if Success then
		continue
	end
	
	warn(`[{Core.__type}]: Module '{Module.Name}' :: {Response}`)
end

for Name, Cache in pairs(Core) do
	if type(Cache) ~= "table" or not Cache.Core or not Cache.Load then
		continue
	end
	
	Cache:Load()
end

return Proxy