local List = {}
List.__index = List

function List:Add(String)
	if self.Prefix then
		String = `[GAdmin {self.Prefix}]: {String}`
	end
	
	if self.AutoPrint then
		print(String)
		return
	end
	
	table.insert(self.List, String)
end

function List:End()
	local Spaces = ""
	for i = 1, #self.Header - 8 do
		Spaces ..= " "
	end
	
	--== GAdmin v2 ==--
	--==		   ==--
	
	table.insert(self.List, `--=={Spaces}==--`)
	if self.AutoPrint then
		print(`--=={Spaces}==--`)
	else
		for i, String in ipairs(self.List) do
			print(String)
		end
	end
	
	self:Destroy()
end

function List:Destroy()
	table.remove(self)
	setmetatable(self, nil)
end

return List