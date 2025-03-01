--== << Services >>

--==

local TEMPLATE = {}
TEMPLATE.Name = "_TEMPLATE" -- Name of location.
TEMPLATE.Previous = { 
	
	-- If set to not nil, will make button 'Back' to appear so that user could go back to the previous frame.
	
	Place = "Main", -- Where to go back to.
	Page = 1, -- What page to go back to.
	
}

--[[

	Another example of TEMPLATE.Previous:
	
	TEMPLATE.Previous = function(Location)
		return Location.Previous
	end
	
	@Location: Current location of user in interface.

]]

TEMPLATE.Page = 0 -- CONSTANT: Current page index where the user are.
TEMPLATE.MaxPages = 0 -- CONSTANT: Maximum amount of pages .

TEMPLATE.Arguments = {
	-- Constant arguments of location.
}

--[[
	Same as Set method, but will only be called when Interface loads in.
	@UI: ScreenGui of GAdmin.
	@Frame: Frame of the Place.
	@Interface: Interface itself.
]]
function TEMPLATE:Load(UI, Frame, Interface)
	
end

--[[
	Gets called before Reload method.
	Has more flexability than Reload itself.
	
	@UI: ScreenGui of GAdmin.
	@Frame: Frame of the Place.
	@Page: Page frame of the place.
	@Arguments: Table of arguments provided inside of Interface:Reload() method.
]]
function TEMPLATE:Set(UI, Frame, Page, Arguments, Interface)
	
end

--[[
	Gets called when user opened location.
	@Page: Frame of page that user is currently in.
	@Interface: Interface itself.
]]
function TEMPLATE:Reload(Page, Interface)
	
end

return TEMPLATE