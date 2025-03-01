--[[
	Refreshes banlist cache that is given to the client.
]]

--== << Services >>
local Data = require(_G.GAdmin.Path.Server.Data)
local Configuration = require(Data.Settings.Main)

local API = require(_G.GAdmin.Path.Server.Services.API)
local DataStore = require(_G.GAdmin.Path.Server.Services.DataStore)
--==

local Load = {}
Load.Server = {}
Load.Client = {}

function Load.Server:Run()
	_G.GAdmin.Scheduler:Insert("Global", "BanlistRefreshment", function()
		local Banlist = API:GetBanlist("Global")
		DataStore:Save("System", "Banlist", Banlist)
	end, 500)
	
	while task.wait() do
		Data.BanlistCache = API:GetBanlist("Formatted")
		task.wait(Configuration.BanlistRefreshment)
	end
end

return Load