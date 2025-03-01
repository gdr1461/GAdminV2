--== << Services >>
local CollectionService = game:GetService("CollectionService")
local Main = script:FindFirstAncestor("GAdminShared")

local Side = game.Players.LocalPlayer == nil and "Server" or "Client"
local OppositeSide = Side == "Server" and "Client" or "Server"

local PathHandler = require(Main.Shared.Services.Core.Path)
local ParameterTable = require(script.Parameters)
--==

local Proxy = newproxy(true)
local Addons = getmetatable(Proxy)

Addons.__type = "GAdmin Addons"
Addons.__metatable = "[GAdmin Addons]: Metatable methods are restricted."
Addons.Loaded = {}

function Addons:__tostring()
	return self.__type
end

function Addons:__index(Key)
	return Addons[Key]
end

function Addons:Reload()
	local Folders = self:Get()
	for i, Addon in ipairs(Folders) do
		self:Load(Addon)
	end
end

function Addons:Load(Addon)
	if self.Loaded[Addon] then
		return
	end
	
	_G.GAdmin.Modified = true
	self.Loaded[Addon] = {
		Config = require(Addon.Config),
		Main = require(Addon.Main),
		Assets = Addon.Assets
	}
	
	self.Loaded[Addon].Enabled = self.Loaded[Addon].Config.Enabled
	if not self.Loaded[Addon].Enabled then
		self.Loaded[Addon] = nil
		return
	end
	
	local Success, Response = self:IsVersionValid(self.Loaded[Addon].Config.Version)
	if not Success then
		self.Loaded[Addon] = nil
		warn(`[{self.__type}]: Error in addon '{Addon}': Invalid Version format :: {Response}`)
		return
	end
	
	local Success, Response = self:IsAuthorValid(self.Loaded[Addon].Config.Author)
	if not Success then
		self.Loaded[Addon] = nil
		warn(`[{self.__type}]: Error in addon '{Addon}': Invalid author format :: {Response}`)
		return
	end
	
	local Success, Response = self:IsTagValid(self.Loaded[Addon].Config.Tag)
	if not Success then
		self.Loaded[Addon] = nil
		warn(`[{self.__type}]: Error in addon '{Addon}': Invalid tag format :: {Response}`)
		return
	end
	
	self.Loaded[Addon].Main[OppositeSide] = {}
	self.Loaded[Addon].Main[Side][Side] = Side == "Server" and _G.GAdmin.Path.Server or Main.Client
	
	self.Loaded[Addon].Main[Side].Shared = Main.Shared
	self.Loaded[Addon].Main[Side].Assets = Addon.Assets
	
	self.Loaded[Addon].Thread = task.spawn(function()
		self:LoadParameters(Addon)
		self.Loaded[Addon].Main[Side]:Start()
	end)
end

function Addons:GetAddonObject(Addon, Path)
	local Object = PathHandler:Get({
		Path = Path,
		Restricted = false,
		
		Paths = {
			["@this"] = function()
				return Addon
			end,
		}
	})
	
	return Object
end

function Addons:LoadParameters(Addon)
	if not self.Loaded[Addon] then
		warn(`[{self.__type}]: Unable to load parameters of undefined addon.`)
		return
	end
	
	if not self.Loaded[Addon].Config.Parameters then
		return
	end
	
	local Cache = {}
	for Name, Parameter in pairs(self.Loaded[Addon].Config.Parameters) do
		if type(Parameter) == "table" and Parameter.Custom then
			continue
		end
		
		if not ParameterTable[Name] then
			warn(`[{self.__type}]: Parameter '{Name}' has no handler. Please make this parameter onto the table with key 'Custom' set to true.`)
			continue
		end
		
		local ParameterData = {
			Side = Side,
			Manager = self,
			Addon = Addon,
			AddonData = self.Loaded[Addon],
			Value = Parameter,
		}
		
		local Request = ParameterTable[Name](ParameterData)
		if not Request.Success then
			warn(`[{self.__type}]: Parameter '{Name}' :: {Request.Response}`)
			continue
		end
		
		if not Request.Response then
			continue
		end
		
		Cache[Request.Response.Name] = Request.Response.Value
	end
end

function Addons:GetParameters(Addon)
	local Parameters = {}
	if not self.Loaded[Addon].Config.Parameters then
		return Parameters
	end
	
	for Name, Parameter in pairs(self.Loaded[Addon].Config.Parameters) do
		table.insert(Parameters, `{Name}`)
	end
	
	return Parameters
end

function Addons:IsTagValid(AddonTag)
	if AddonTag == nil then
		return true
	end
	
	if type(AddonTag) ~= "string" then
		return false, "Addon tag must be a string."
	end

	return true
end

function Addons:IsAuthorValid(AddonAuthor)
	if type(AddonAuthor) ~= "string" then
		return false, "Addon author must be a string."
	end
	
	if AddonAuthor:sub(1, 1) ~= "@" then
		return false, "Addon author must start with '@'."
	end
	
	return true
end

function Addons:IsVersionValid(AddonVersion)
	if type(AddonVersion) ~= "string" then
		return false, "Addon version must be a string."
	end
	
	if AddonVersion:sub(1, 1) ~= "v" then
		return false, "Addon version must start with 'v'."
	end
	
	if AddonVersion:sub(2, #AddonVersion):find("%a+") then
		return false, "Addon version must contain only numbers and symbols."
	end
	
	return true
end

function Addons:Get()
	local Objects = CollectionService:GetTagged("GAdmin Addon")
	local Folders = {}
	
	for i, Object in ipairs(Objects) do
		if not Object:IsA("Folder") or not Object:FindFirstChild("Config") or not Object:FindFirstChild("Main") or not Object:FindFirstChild("Assets") then
			continue
		end
		
		table.insert(Folders, Object)
	end
	
	return Folders
end

return Proxy