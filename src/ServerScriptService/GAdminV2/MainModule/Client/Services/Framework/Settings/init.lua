--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Cache = require(Main.Client.Services.Framework.Cache)

local Remote = require(Main.Shared.Services.Remote)
local Popup = require(Main.Shared.Services.Popup)

local UI = require(Main.Client.Services.UI)
local Gui = UI.Gui

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
local SettingAssets = Assets.Settings
--==

local Proxy = newproxy(true)
local Settings = getmetatable(Proxy)

Settings.__type = "GAdmin Settings"
Settings.__metatable = "[GAdmin Settings]: Metatable methods are restricted."

Settings.Settings = {}
Settings.Page = Gui.MainFrame.Places.Settings.Pages["1"]

Settings.Content = require(script.Content)
Settings.Inputs = require(script.Inputs)

function Settings:__tostring()
	return self.__type
end

function Settings:__index(Key)
	return Settings[Key]
end

function Settings:Reload()
	self:Clear()
	self:Load()

	for i, Setting in ipairs(self.Content.Settings) do
		self:LoadSetting(Setting, i)
	end
end

function Settings:Load()
	local SessionSettings = Cache.Session.Settings
	for i, Setting in ipairs(self.Content.Settings) do
		Setting:LoadData(SessionSettings, Cache.Session)
	end
end

function Settings:LoadSetting(Setting, Index)
	local InputTemplate = SettingAssets:FindFirstChild(Setting.Type)
	if not InputTemplate then
		warn(`[{self.__type}]: Setting type of '{Setting.Type}' is invalid.`)
		return
	end

	local Frame = GuiAssets.Setting:Clone()
	Frame.Name = Setting.Name

	Frame.Title.Scrollable.Title.Text = Setting.Name
	Frame.Description.Scrollable.Description.Text = Setting.Description or "No description."

	local Input = InputTemplate:Clone()
	Input.Visible = true
	Input.Parent = Frame.InputFrame

	local InputHandler = self.Inputs[Setting.Type]
	self.Settings[Setting.Name] = {
		Object = Input,
		Default = Setting.Default,
	}

	local Default = InputHandler.GetDefault(self.Settings[Setting.Name])
	self.Settings[Setting.Name].Value = Default
	self.Settings[Setting.Name].OldValue = Default

	self.Settings[Setting.Name].Connections = InputHandler.Connect(self.Settings[Setting.Name], function(Value)
		self.Settings[Setting.Name].OldValue = self.Settings[Setting.Name].Value
		self.Settings[Setting.Name].Value = Value

		local Value = Setting.Callback(self.Settings[Setting.Name], Cache.Session.Settings)
		self.Settings[Setting.Name].Value = Value
	end)

	InputHandler.Set(self.Settings[Setting.Name], Default)
	Frame.LayoutOrder = Index or #self.Page.List:GetChildren() + 1
	Frame.Parent = self.Page.List
end

function Settings:Save()
	local SessionSettings = Cache.Session.Settings
	local Custom = {}

	for i, Setting in ipairs(self.Content.Settings) do
		local ReturnSettings, ReturnSession = Setting:SaveData(self.Settings[Setting.Name], SessionSettings, Cache.Session)
		SessionSettings = ReturnSettings

		if ReturnSession then
			Cache.Session[ReturnSession[1]] = ReturnSession[2]
			Custom[Setting.Name] = ReturnSession
		end
	end

	local Success, Response = Remote:Fire("SetSettings", SessionSettings, Custom)
	if Success then
		return
	end

	Popup:New({
		Type = "Error",
		Text = `[SETTINGS]: {Response}`,
		Time = 20,
	})
end

function Settings:Clear()
	for Name, Data in pairs(self.Settings) do
		for i, Connection in ipairs(Data.Connections) do
			pcall(function()
				Connection:Destroy()
			end)

			pcall(function()
				Connection:Disconnect()
			end)
		end

		Data.Object.Parent.Parent:Destroy()
	end
end

function Settings:Add(Setting)
	local Structure = {
		Name = Setting.Name,
		Description = Setting.Description or "N/A",
		
		Type = Setting.Type,
		Default = Setting.Default,
		
		Callback = Setting.Callback,
		LoadData = Setting.LoadData or function(self, Settings)
			print(Settings[self.Name])
			self.Default = Settings[self.Name]
		end,
		
		SaveData = Setting.SaveData or function(self, Request, Settings)
			print(Request.Value)
			Settings[self.Name] = Request.Value ~= nil
			print(Settings[self.Name])
			return Settings
		end,
	}
	
	table.insert(self.Content.Settings, Structure)
	self:LoadSetting(Structure)
end

function Settings:Find(Name: string)
	for i, Setting in ipairs(self.Content.Settings) do
		if Setting.Name:lower():sub(1, #Name) ~= Name:lower() then
			continue
		end

		return table.clone(Setting)
	end
end

local ISettings = require(script.ISettings)
Settings.Config = ISettings:Load(Proxy)

return Proxy