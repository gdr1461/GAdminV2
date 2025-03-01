--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Shared = Main.Shared
--==

local Services = {}
Services.__type = "GAdmin Command Services"

Services.Side = game.Players.LocalPlayer == nil and "Server" or "Client"
Services.__Blocked = {"Server.Parser", "Server.Player", "Shared.Types", "Server.Messages", "Shared.Commands", "Client.Framework"}

function Services:__GetEnums(Folder)
	local Enums = {}
	for i, Service in ipairs(Folder:GetChildren()) do
		if not Service:IsA("ModuleScript") or table.find(self.__Blocked, `{Folder.Parent.Name}.{Service.Name}`) then
			continue
		end

		Enums[Service.Name] = Service
	end

	return Enums
end

function Services:GetEnums()
	local Enums = self:__GetEnums(Shared.Services)
	local Folder = self.Side == "Server" and _G.GAdmin.Path.Server.Services or Main.Client.Services
	local LocalEnums = self:__GetEnums(Folder)
	
	for Item, Value in pairs(LocalEnums) do
		if Enums[Item] then
			warn(`[{self.__type}]: Enum item with name '{Item}' is taken.`)
			continue
		end
		
		Enums[Item] = Value
	end
	
	return Enums
end

function Services:Require(Enums)
	local Loaded = {}
	for Item, Module in pairs(Enums) do
		local Success, Response = pcall(function()
			return require(Module)
		end)
		
		if not Success then
			warn(`[{self.__type}]: {Item} :: {Response}`)
			continue
		end
		
		Loaded[Item] = Response
	end
	
	return Loaded
end

return Services