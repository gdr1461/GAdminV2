--== << Services >>
local RunService = game:GetService("RunService")
local Main = script:FindFirstAncestor("MainModule")
--==

local Data = {}
Data.InStudio = RunService:IsStudio()

Data.Client = Main.Client
Data.Server = Main.Server
Data.Shared = Main.Shared
Data.Settings = Main.Settings

local RequiredSettings = require(Main.Settings.Main)
local PlayerSettings = require(Main.Settings.PlayerData)
local Ranks = require(Main.Settings.Ranks)

Data.DataStores = {
	Player = {
		Rank = RequiredSettings.Rank,
		RankExpiration = nil,
		Prefix = RequiredSettings.Prefix,
		Defaults = RequiredSettings.Defaults,
		Settings = PlayerSettings,
	},
	
	Code = {},
	
	System = {
		Ranks = Ranks.Ranks,
		Banlist = {}
	},
}

Data.RankInterface = {
	Name = "N/A",
	Rank = 4.1,
	Players = {},
	Color = Color3.new(0.333333, 0.333333, 0.333333)
}

Data.RankCache = Ranks.Ranks
Data.LastRankRefresh = 0

Data.ConnectionBase = {}
Data.Logs = {}
Data.ChatLogs = {}

Data.BanlistCache = {}
Data.ServerBans = {
	["1"] = {
		"1", -- Moderator
		"Testing ban frame.", -- Reason
		tostring(DateTime.now().UnixTimestamp + 9999), -- Time
		tostring(DateTime.now().UnixTimestamp), -- On
		false, -- API
		true, -- Locally
		false, -- ApplyToUniverse
		"Server", -- Type
		"Private Reason.", -- Private Reason.
	}
}

Data.Shutdown = {
	Enabled = false,
	Reason = ""
}

Data.Icon = 18301407260
Data.InternalConfig = 123930917497029

task.defer(function()
	local Executor = require(Main.Server.Services.Executor)
	Data.MainExecutor = Executor.new()
	
	local Table = require(Data.Shared.Services.Core.Table)
	while task.wait(60) do
		local LogCache = {}
		local LogLimit = #Data.Logs
		
		local ChatCache = {}
		local ChatLimit = #Data.ChatLogs
		
		Data.Logs = Table:GetPart(Data.Logs, 100)
		Data.ChatLogs = Table:GetPart(Data.ChatLogs, 100)
	end
end)

return Data