--== << Services >>
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Main = script:FindFirstAncestor("GAdminShared")
local GetSideServices = require(Main.Shared.Services.Core.GetSideServices)
local Side = game.Players.LocalPlayer == nil and "Server" or "Client"
--==

local Proxy = newproxy(true)
local Loader = getmetatable(Proxy)

Loader.__type = "GAdmin AutoLoader"
Loader.__metatable = "[GAdmin AutoLoader]: Metatable methods are restricted."

Loader.Memory = {}
Loader.Side = Side

function Loader:__tostring()
	return self.__type
end

function Loader:__index(Key)
	return Loader[Key]
end

function Loader:Start()
	local Folders = CollectionService:GetTagged("GA_Load")
	if #Folders <= 0 then
		local Folder = Instance.new("Folder")
		Folder.Name = "GA_Load"
		table.insert(Folders, Folder)
	end
	
	if Side == "Server" then
		local Folder = Instance.new("Folder")
		Folder.Name = "GAdminLoader"
		Folder.Parent = ReplicatedStorage
	end
	
	for i, Folder in ipairs(Folders) do
		self:LoadFolder(Folder)
	end
end

function Loader:LoadFolder(Folder)
	Folder.Parent = ReplicatedStorage.GAdminLoader
	local RawEnums = GetSideServices:GetEnums(Side)
	local Enums = GetSideServices:Require(RawEnums)
	
	for i, Module in ipairs(Folder:GetChildren()) do
		if not Module:IsA("ModuleScript") or self.Memory[Module] then
			continue
		end

		local ModuleSide = Module:GetAttribute("Side") or "Global"
		if not table.find({"Global", Side}, ModuleSide) then
			continue
		end

		local Success, Load = pcall(function()
			return require(Module)
		end)

		if not Success then
			warn(`[{self.__type}]: Module '{Module.Name}' :: {Load}`)
			continue
		end
		
		if not Load[self.Side] then
			warn(`[{self.__type}]: Module '{Module.Name}' :: Module must contain table named '{self.Side}' for it to load.`)
			continue
		end

		if not Load[self.Side].Run or type(Load[self.Side].Run) ~= "function" then
			warn(`[{self.__type}]: Module '{Module.Name}' :: Module must contain Run method for it to load.`)
			continue
		end

		if not Module:GetAttribute("__GA_Official") then
			_G.GAdmin.Modified = true
		end

		Load[self.Side].Cache = {}
		Load[self.Side].Services = Enums
		Load[self.Side].Data = self.Side == "Server" and require(_G.GAdmin.Path.Server.Data) or nil

		Load[self.Side].Get = function(self, Module)
			self.Cache[Module] = self.Cache[Module] or (typeof(Module) == "Instance" and require(Module) or Module)
			return self.Cache[Module]
		end

		self.Memory[Module] = {
			Cache = Load,
			Thread = task.defer(function()
				Load[self.Side]:Run()
			end)
		}
	end
end

return Proxy