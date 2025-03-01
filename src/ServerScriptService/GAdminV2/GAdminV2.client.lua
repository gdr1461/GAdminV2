task.wait(1)
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainModule = ReplicatedStorage:WaitForChild("MainModule")
local GAdminShared = ReplicatedStorage.GAdminShared

for i, Module in ipairs(GAdminShared.Shared.Services:GetChildren()) do
	task.spawn(function()
		local RequiredModule = require(Module)
		if Module.Name == "Remote" then
			local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
			RequiredModule:Set(GAdminShared.Client.Remotes)
		end
	end)
end

script.Name = HttpService:GenerateGUID(false)
MainModule.Name = HttpService:GenerateGUID(false)

_G.GAdmin = {
	Path = GAdminShared,
	Render = require(GAdminShared.Shared.Services.Render),
	
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
	end,
}

local Scheduler = require(GAdminShared.Shared.Services.Scheduler)
Scheduler:Load()

local Framework = require(GAdminShared.Client.Services.Framework)
Framework:Load()
_G.GAdmin.Framework = Framework

local Interface = require(GAdminShared.Client.Services.Framework.Interface)
local Rank = require(GAdminShared.Shared.Services.Rank)
local Popup = require(GAdminShared.Shared.Services.Popup)

local Restrictions = require(GAdminShared.Settings.Restrictions)
local Settings = require(GAdminShared.Settings.Main)

local Cache = require(GAdminShared.Client.Services.Framework.Cache)
local RankData = Rank:Find(Cache.Session.Rank)

repeat
	task.wait()
until Cache.VersionLog

local GAMessage = GAdminShared.Shared.Assets.Gui.GAMessage:Clone()
GAMessage.Parent = player.PlayerGui

if Restrictions.WelcomePopup > Cache.Session.Rank then
	return
end

local IsSandbox = Settings.Sandbox and (RunService:IsStudio() or Settings.__GAdmin_TestingPlace_Sandbox_Everywhere)
Cache.Session.Rank = IsSandbox and Settings.SandboxRank or Cache.Session.Rank

if not Cache.VersionLog.Valid then
	Popup:New({
		Type = "Warning",
		Text = `Version <font color="#ffbfaa">{Cache.VersionLog.Given}</font> of GAdmin is modified or not valid anymore. Please, install <font color="#ffbfaa">{Cache.VersionLog.Latest}</font>.`,
		Time = 120,
	})
elseif Cache.VersionLog.Outdated then
	Popup:New({
		Type = "Warning",
		Text = `Version <font color="#ffbfaa">{Cache.VersionLog.Given}</font> of GAdmin is outdated. Please, install <font color="#ffbfaa">{Cache.VersionLog.Latest}</font>.`,
		Time = 120,
	})
end

Popup:New({
	Type = "Notice",
	Text = `Welcome! Your rank is '<font color="#ffbfaa">{RankData.Name}</font>', click to see more.`,
	
	Time = 60,
	Interact = function()
		Interface:Open(nil, nil, true)
		Interface:SetLocation("Commands", 1)
	end,
})