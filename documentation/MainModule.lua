--[=[
	@class MainModule
	@server
	@tag Core
	Main module that loads GAdminV2.
]=]

--[=[
	@interface MainModule
	@field __type string
	@field __version string
	@field Loaded boolean
	@field IsServer boolean
	@field Load () -> nil
	@field GetData () -> table
	@field Replace () -> nil
	@field Settings () -> boolean
	@within MainModule
]=]

--== << Services >>

local RunService = game:GetService("RunService")
local Types = require(script.Shared.Types)
local Commands

local Data = require(script.Server.Data)
local Player

local RankService
local Console = require(script.Shared.Services.Console)
local Settings = require(Data.Settings.Main)

local Remote
local Messages

--==

local Proxy = newproxy(true)
local GAdmin = getmetatable(Proxy)

GAdmin.__type = "GAdmin v2"

--[=[
	The current version of GAdminV2 in use.

	@prop __version string
	@within MainModule
]=]
GAdmin.__version = "BETA-v2.0.0"

GAdmin.__metatable = "[GAdmin]: Metatable methods are restricted."

--[=[
	Indicates whether GAdminV2 has been loaded.

	@prop Loaded boolean
	@within MainModule
]=]
GAdmin.Loaded = false

--[=[
	Checks if the main module has been required on the server side.

	This will always be `true`, as it does not function on the client side

	@private
	@prop IsServer boolean
	@within MainModule
]=]
GAdmin.IsServer = RunService:IsServer()
if not GAdmin.IsServer then
	warn(`[{GAdmin.__type}]: Unable to access main module from client.`)
	return {}
end

function GAdmin:__tostring()
	return self.__type, self.__version
end

function GAdmin:__index(Key)
	return GAdmin[Key]
end

--[=[
	Initializes GAdminV2 systems.

	@private
	@within MainModule
	@return nil
]=]
function GAdmin:Load()
	if self.Loaded then
		return
	end
	
	GAdmin.Loaded = true
	local List = Console:List("GAdmin v2", true)
	
	List.AutoPrint = true
	List.Prefix = "Main"
	
	List:Add("Loading Systems..")
	self:Replace()
	
	local Success = self:Settings()
	if not Success then
		return
	end
	
	Commands = require(Data.Shared.Services.Commands)
	Player = require(Data.Server.Services.Player)
	
	Remote = require(Data.Shared.Services.Remote)
	Messages = require(script.Server.Services.Messages)
	_G.GAdmin.API = require(script.Server.Services.API)
	
	RankService = require(Data.Shared.Services.Rank)
	Data.ConnectionBase.RankReload = RunService.Heartbeat:Connect(function()
		if tick() - Data.LastRankRefresh < Settings.RankRefreshment then
			return
		end
		
		Data.LastRankRefresh = tick()
		RankService:Reload()
	end)
	
	Commands:Reload()
	Remote:Set(Data.Client.Remotes)
	
	Player:Load(require(script.Server.Services.API))
	Messages:Load()
	
	local AutoLoader = require(Data.Shared.Services.AutoLoader)
	AutoLoader:Start()
	
	_G.GAdmin.Render = require(Data.Shared.Services.Render)
	local Scheduler = require(Data.Shared.Services.Scheduler)
	Scheduler:Load()
	
	List:Add("Systems loaded successfully.")
	List:End()
	
	local Addons = require(Data.Shared.Services.Addons)
	Addons:Reload()
	
	local VersionChecker = require(Data.InternalConfig)
	local CheckLog = VersionChecker:Check(self.__version)
	
	CheckLog.Logs = VersionChecker.Logs
	Data.VersionLog = CheckLog
	
	Data.PrefixData = VersionChecker.PrefixData
	Data.AssetId = VersionChecker.AssetId
	Data.Donations = VersionChecker.Donations
	
	if CheckLog.Outdated then
		warn(`[{self.__type}]: Version {CheckLog.Given} of GAdmin is outdated. Please, install {CheckLog.Latest}.`)
	end
	
	if not CheckLog.Valid then
		warn(`[{self.__type}]: Version {CheckLog.Given} of GAdmin is modified or not valid anymore. Please, install {CheckLog.Latest}.`)
	end
end

--[=[
	Returns the data table containing all the data used by GAdminV2.

	@private
	@within MainModule
	@return table
]=]
function GAdmin:GetData()
	return Data
end

--[=[
	Creates the `GAdminShared` folder and places it in `ReplicatedStorage`.

	@private
	@within MainModule
	@return nil
]=]
function GAdmin:Replace()
	local Folder = Instance.new("Folder")
	Folder.Name = "GAdminShared"
	Folder.Parent = game.ReplicatedStorage
	
	local Gui = script.Shared.Assets.Gui:FindFirstChild("GAdmin")
	if Gui then
		Gui.Parent = game.StarterGui
		Gui.MainFrame.Visible = false
	end
	
	script.Shared.Parent = Folder
	script.Settings.Parent = Folder
	script.Client.Parent = Folder
end

--[=[
	Verifies that all settings are loaded correctly.

	@private
	@within MainModule
	@return boolean
]=]
function GAdmin:Settings()
	for i, Setting in ipairs(Data.Settings:GetChildren()) do
		local Success, Error = pcall(function()
			require(Setting)
		end)
		
		if Success then
			continue
		end
		
		warn(`[{self.__type}]: Got an error while loading settings category '{Setting.Name}'. Check it to see what is wrong. Error: {Error}`)
		return false
	end
	
	return true
end

_G.GAdmin = {
	Path = script,
	Module = Proxy,
	
	__GetBanData = function(BanData)
		local Ban = {
			Moderator = BanData[1],
			Reason = BanData[2],
			Time = BanData[3],
			On = BanData[4],
			API = BanData[5],
			Locally = BanData[6],
			ApplyToUniverse = BanData[7],
			Type = BanData[8],
			PrivateReason = BanData[9]
		}
		
		for Key, Value in pairs(BanData) do
			if type(Key) == "number" or Ban[Key] then
				continue
			end
			
			Ban[Key] = Value
		end
		
		return Ban
	end
}

return Proxy