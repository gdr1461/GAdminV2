--== << Services >>
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Main = ReplicatedStorage.GAdminShared
--==

local Place = {}
Place.Name = "PLACENAME"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	
end

function Place:Reload(Page, Interface)
	
end

return Place