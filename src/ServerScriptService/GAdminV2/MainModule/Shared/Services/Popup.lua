--== << Services >>

local Main = script:FindFirstAncestor("GAdminShared")
local Remote = require(Main.Shared.Services.Remote)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local Sound = require(Main.Shared.Services.Sound)
local Table = require(Main.Shared.Services.Core.Table)

local Settings = require(Main.Settings.Interface)
local Display = game.Players.LocalPlayer and require(Main.Client.Services.Framework.Display) or nil

--==

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Proxy = newproxy(true)
local Popup = getmetatable(Proxy)

Popup.__type = "GAdmin Popup"
Popup.__metatable = "[GAdmin Popup]: Metatable methods are restricted."
Popup.History = {}

function Popup:__tostring()
	return self.__type
end

function Popup:__index(Key)
	return Popup[Key]
end

function Popup:New(Data)
	if not Settings.ShowPopups then
		return
	end
	
	if IsServer then
		Remote:Fire("Popup", Data.Player, Data)
		return
	end
	
	Data.Type = Data.Type or "Notice"
	Data.Time = Data.Time or 10
	
	if not table.find({"Notice", "Warning", "Error"}, Data.Type) then
		warn(`[{self.__type}]: Popup type '{Data.Type}' is invalid.`)
		return
	end
	
	Sound:Play({
		Category = "Notification",
		Name = Data.Type,
	})
	
	Data.Title = Data.Title or Data.Type
	Data.OnEnd = Data.OnEnd or function(Frame, Options)
		
	end
	
	local Frame = GuiAssets.Popup:Clone()
	Display.Popup(Frame, Data)
	
	table.insert(Popup.History, {
		Type = Data.Type,
		Title = Data.Title,
		Text = Data.Text and tostring(Data.Text) or "N/A",
		Time = Data.Time,
		Interaction = Data.Interact
	})
	
	Popup.History = Table:GetPart(Popup.History, 100)
end

if not IsServer then
	Remote:Connect("Popup", function(...)
		Popup:New(...)
	end)
end

return Proxy