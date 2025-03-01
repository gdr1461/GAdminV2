local Path = {}

function Path:Get(Settings)
	Settings = Settings or {}
	Settings.Paths = Settings.Paths or {}

	if not Settings.Path then
		warn(`[GAdmin Core]: GetPath :: Settings.Path is required.`)
		return
	end

	local Split = Settings.Path:split(".")
	local Object = self:Custom(Settings.Paths, Split[1]) or game:GetService(Split[1])
	
	if not Object then
		return
	end
	
	table.remove(Split, 1)
	for i, Name in ipairs(Split) do
		local Child = self:Custom(Settings.Paths, Name) or Object:FindFirstChild(Name)
		
		if not Child then
			return
		end
		
		Object = Child
	end

	return Object
end

function Path:Custom(Paths, String)
	if not Paths[String] then
		return
	end
	
	return Paths[String]()
end

return Path