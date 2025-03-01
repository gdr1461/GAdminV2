--== << Services >>
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Main = script:FindFirstAncestor("GAdminShared")
local GuiAssets = Main.Shared.Assets.Gui

local Interface = require(script.Interface)
local DisplayHandler = require(script.Display)

local Settings = require(Main.Settings.Main)
local Remote = require(Main.Shared.Services.Remote)

local AutoLoader = require(Main.Shared.Services.AutoLoader)
local Cache = require(script.Cache)
--==

local Proxy = newproxy(true)
local Framework = getmetatable(Proxy)

Framework.__type = "GAdmin Framework"
Framework.__metatable = "[GAdmin Framework]: Metatable methods are restricted."

Framework.Interface = Interface
Framework.Cache = Cache

Framework.UI = require(Main.Client.Services.UI)
Framework.Display = DisplayHandler

function Framework:__tostring()
	return self.__type
end

function Framework:__index(Key)
	return Framework[Key]
end

function Framework:__newindex(Key, Value)
	Framework[Key] = Value
end

function Framework:Load()
	local IsStudio = RunService:IsStudio()
	self.UI.Gui.MainFrame.Size = IsStudio and UDim2.new(.4, 20, .5, 20) or UDim2.new(.3, 20, .4, 20)
	self.UI.Gui.Notifications.Size = IsStudio and UDim2.fromScale(.2, .2) or UDim2.fromScale(.17, .17)
	
	Cache.Session = Remote:Fire("GetInfo")
	Remote:Connect("UpdateInfo", function(Info)
		local IsSandbox = Settings.Sandbox and (IsStudio or Settings.__GAdmin_TestingPlace_Sandbox_Everywhere)
		Cache.Session = Info
		
		Cache.Session.Rank = IsSandbox and Settings.SandboxRank or Cache.Session.Rank
		Interface:Reload()
	end)
	
	if Cache.Session.Settings.LoadDelay and Cache.Session.Settings.LoadDelay > 0 then
		task.wait(Cache.Session.Settings.LoadDelay)
	end
	
	local Draggable = self:Display("Draggable", Interface.UI.MainFrame)
	Draggable:Enable()
	self.Draggable = Draggable
	
	Interface.UI.MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
		local Position = Interface.UI.MainFrame.Position
		local X, Y = Interface.UI.AbsoluteSize.X / 2, Interface.UI.AbsoluteSize.Y / 2
		local OutOfBounds = Position.X.Offset > X or Position.Y.Offset > Y or Position.X.Scale < -X or Position.Y.Scale < -Y
		
		if not OutOfBounds then
			return
		end
		
		Interface.UI.MainFrame.Position = UDim2.fromScale(.5, .5)
		warn(`[{self.__type}]: Detected out of bounds UI.`)
	end)
	
	Cache.ParserThread = task.defer(function()
		require(script.Parser):Load()
		local Chat = require(Main.Client.Services.Chat)

		Chat:Load()
		Chat:SetChat(0)
		self.Chat = Chat
	end)
	
	Interface:Load()
	AutoLoader:Start()
	
	local Addons = require(Main.Shared.Services.Addons)
	Addons:Reload()

	if _G.GAdmin.Modified then
		Interface.UI.MainFrame.Bottom.Title.Text = `GAdmin <font color="#5a00f5">MODIFIED</font>`
		Interface:SetHover(Interface.UI.MainFrame.Bottom.Title, `This game uses a modified version of GAdmin. Be aware that addons may introduce inappropriate or potentially dangerous content.`)
	end
end

function Framework:Trigger(Data)
	Data = Data or {}
	Data.Place = Data.Place or Interface.Location.Place
	
	Data.Method = Data.Method or "Reload"
	Data.Arguments = Data.Arguments or {}
	
	local PlaceData = Interface:GetData(Data.Place)
	if not PlaceData then
		warn(`[{self.__type}]: Unable to get data of UI Place '{Data.Place}'.`)
		return
	end
	
	if not PlaceData[Data.Method] or type(PlaceData[Data.Method]) ~= "function" then
		warn(`[{self.__type}]: Unable to get method '{Data.Method}' of the UI Place '{Data.Place}'.`)
		return
	end
	
	return PlaceData[Data.Method](PlaceData[Data.Method], unpack(Data.Arguments))
end

function Framework:Display(Name, ...)
	local GuiObject = GuiAssets:FindFirstChild(Name)
	if not GuiObject then
		warn(`[{self.__type}]: Unable to find object with the name '{Name}' in Gui Assets.`)
		return
	end
	
	if not DisplayHandler[Name] then
		warn(`[{self.__type}]: Unable to find handler for display with the name '{Name}' in Display Framework.`)
		return
	end
	
	local NewObject = GuiObject:Clone()
	return DisplayHandler[Name](NewObject, ...)
end

return Proxy