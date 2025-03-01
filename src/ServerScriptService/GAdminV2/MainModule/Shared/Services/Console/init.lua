local Shared = script:FindFirstAncestor("Shared")
local Types = require(Shared.Types)
local ListMeta = require(script.List)

local Proxy = newproxy(true)
local Console: Types.ConsoleService = getmetatable(Proxy)

Console.__type = "GAdmin Console"
Console.__metatable = "[GAdmin Console]: Metatable methods are restricted."

function Console:__tostring()
	return self.__type
end

function Console:__index(Key)
	return Console[Key]
end

function Console:List(Title, AutoPrint)
	if AutoPrint == nil then
		AutoPrint = false
	end
	
	Title = Title or "GAdmin v2"
	local List = setmetatable({}, ListMeta)
	
	List.Header = `--== {Title} ==--`
	List.List = {not AutoPrint and List.Header or nil}
	List.AutoPrint = AutoPrint
	
	if AutoPrint then
		print(List.Header)
	end
	
	return List
end

return Proxy :: Types.ConsoleService