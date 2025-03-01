--[[

	Last update to the github source: 15:57 01.03.2025

]]

--[[

	TODO:
	
	Смотри трелло

]]

local HttpService = game:GetService("HttpService")
local MainModule = script.MainModule

local CollectionService = game:GetService("CollectionService")
local Configuration = CollectionService:GetTagged("GA_Settings")[1]

if Configuration then
	if MainModule:FindFirstChild("Settings") then
		MainModule.Settings:Destroy()
	end
	
	Configuration.Name = "Settings"
	Configuration.Parent = MainModule
end

local Parent = MainModule.Shared.Assets.Gui:FindFirstChild("GAdmin") or game.StarterGui:FindFirstChild("GAdmin")
if not Parent then
	warn(`[GAdmin Loader]: Unable to find GAdmin UI.`)
	return
end

local Client = script.GAdminV2
Client.Parent = Parent

local GAdmin = require(MainModule)
task.spawn(GAdmin.Load, GAdmin)

MainModule.Parent = game.ReplicatedStorage
Client.Enabled = true

for i, player in ipairs(game.Players:GetPlayers()) do
	Parent:Clone().Parent = player.PlayerGui
end