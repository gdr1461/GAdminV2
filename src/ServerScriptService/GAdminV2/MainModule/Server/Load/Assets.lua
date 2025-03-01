--[[
	Preloads assets from the path MainModule.Shared.Assets so icons won't be loaded on time.
]]

--== << Services >>
local ContentProvider = game:GetService("ContentProvider")
local Main = _G.GAdmin.Path
local Assets = Main.Shared.Assets
--==

local Load = {}
Load.Server = {}
Load.Client = {}

function Load.Client:Run()
	ContentProvider:PreloadAsync(Assets:GetDescendants())
end

return Load