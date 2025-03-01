--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")

local Commands
local Builder

local RankService = require(Main.Shared.Services.Rank)
local Settings = Players.LocalPlayer == nil and require(_G.GAdmin.Path.Server.Services.Player.Settings) or require(Main.Client.Services.Framework.Settings)
--==

return {
	__Test = function(Parameter)
		local Object = Parameter.Manager:GetAddonObject(Parameter.Addon, Parameter.Value)
		if not Object then
			return {
				Success = false,
				Response = `Object from path has not been found.`
			}
		end
		
		print(Object)
		return {
			Success = true
		}
	end,
	
	Settings = function(Parameter)
		Commands = Commands or require(Main.Shared.Services.Commands)
		local Object = Parameter.Manager:GetAddonObject(Parameter.Addon, Parameter.Value)
		
		if not Object then
			return {
				Success = false,
				Response = `Object from path has not been found.`
			}
		end

		if not Object:IsA("Folder") then
			return {
				Success = false,
				Response = `Object must be type of Folder, not {Object.ClassName}.`
			}
		end
		
		for i, Category in ipairs(Object:GetChildren()) do
			local OriginObject = Main.Settings:FindFirstChild(Category.Name)
			if not OriginObject then
				return {
					Success = false,
					Response = `Settings category with name '{Category.Name}' is invalid.`
				}
			end
			
			local Success, Response = pcall(function()
				return require(Category)
			end)
			
			if not Success then
				return {
					Success = false,
					Response = `Unable to load category '{Category.Name}' :: {Response}`
				}
			end
			
			local Origin = require(OriginObject)
			for i, v in pairs(Response) do
				Origin[i] = v
			end
		end
		
		return {
			Success = true
		}
	end,
	
	ISettings = function(Parameter)
		local Object = Parameter.Manager:GetAddonObject(Parameter.Addon, Parameter.Value)
		if not Object then
			return {
				Success = false,
				Response = `Object from path has not been found.`
			}
		end

		if not Object:IsA("ModuleScript") then
			return {
				Success = false,
				Response = `Object must be type of ModuleScript, not {Object.ClassName}.`
			}
		end
		
		local Success, Response = pcall(function()
			return require(Object)
		end)

		if not Success then
			return {
				Success = false,
				Response = Response
			}
		end
		
		local SideHandler = Response[Parameter.Side]
		SideHandler:Load(Settings.Config or Settings)
		
		return {
			Success = true
		}
	end,
	
	Commands = function(Parameter)
		Commands = Commands or require(Main.Shared.Services.Commands)
		local Cache = {}
		local Object = Parameter.Manager:GetAddonObject(Parameter.Addon, Parameter.Value)
		
		if not Object then
			return {
				Success = false,
				Response = `Object from path has not been found.`
			}
		end
		
		if not Object:IsA("Folder") then
			return {
				Success = false,
				Response = `Object must be type of Folder, not {Object.ClassName}.`
			}
		end
		
		Commands:LoadFolder(Object)
		return {
			Success = true,
			Response = {
				Name = "Commands",
				Value = Cache
			}
		}
	end,
	
	Ranks = function(Parameter)
		if Parameter.Side == "Client" then
			return {
				Success = true
			}
		end
		
		local Object = Parameter.Manager:GetAddonObject(Parameter.Addon, Parameter.Value)
		if not Object then
			return {
				Success = false,
				Response = `Object from path has not been found.`
			}
		end
		
		if not Object:IsA("ModuleScript") then
			return {
				Success = false,
				Response = `Object must be type of ModuleScript, not {Object.ClassName}.`
			}
		end
		
		local Success, Response = pcall(function()
			return require(Object)
		end)
		
		if not Success then
			return {
				Success = false,
				Response = Response
			}
		end
		
		for i, Rank in ipairs(Response) do
			Response[i].ByAddon = Parameter.AddonData.Config.Name
		end
		
		RankService:BatchAdd(Response, true)
		return {
			Success = true
		}
	end,
	
	UI = function(Parameter)
		if Parameter.Side == "Server" then
			return {
				Success = true
			}
		end
		
		local Object = Parameter.Manager:GetAddonObject(Parameter.Addon, Parameter.Value)
		if not Object then
			return {
				Success = false,
				Response = `Object from path has not been found.`
			}
		end

		if not Object:IsA("ModuleScript") then
			return {
				Success = false,
				Response = `Object must be type of ModuleScript, not {Object.ClassName}.`
			}
		end
		
		local Success, Response = pcall(function()
			return require(Object)
		end)

		if not Success then
			return {
				Success = false,
				Response = Response
			}
		end
		
		Builder = Builder or require(Main.Client.Services.UI.Builder)
		Response:Load(Players.LocalPlayer, Builder)
		
		return {
			Success = true
		}
	end,
}