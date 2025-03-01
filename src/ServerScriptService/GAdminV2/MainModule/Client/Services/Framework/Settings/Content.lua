--== << Services >>
local TextService = game:GetService("TextService")
local Main = script:FindFirstAncestor("GAdminShared")

local Assets = Main.Shared.Assets
local Remote = require(Main.Shared.Services.Remote)

local UI = require(Main.Client.Services.UI)
local Configuration = require(Main.Settings.Interface)
--==

local Settings = {
	{
		Name = "Button sounds",
		Type = "Slider",

		Description = "Volume of the button sounds.",
		Default = {
			Default = 0.5,
			Min = 0,
			Max = 1,
			Slide = .1,
		},

		LoadData = function(self, Settings)
			self.Default.Default = Settings.Sounds.Buttons
		end,

		SaveData = function(self, Request, Settings)
			Settings.Sounds.Buttons = Request.Value
			return Settings
		end,

		Callback = function(Request)
			for i, Sound in ipairs(Assets.Sounds.Buttons:GetDescendants()) do
				if not Sound:IsA("Sound") then
					continue
				end

				Sound.Volume = Request.Value
			end

			return Request.Value
		end,
	},

	{
		Name = "Popup sounds",
		Type = "Slider",

		Description = "Volume of the popup sounds.",
		Default = {
			Default = 0.5,
			Min = 0,
			Max = 1,
			Slide = .1,
		},

		LoadData = function(self, Settings)
			self.Default.Default = Settings.Sounds.Popups
		end,

		SaveData = function(self, Request, Settings)
			Settings.Sounds.Popups = Request.Value
			return Settings
		end,

		Callback = function(Request)
			for i, Sound in ipairs(Assets.Sounds.Notification:GetDescendants()) do
				if not Sound:IsA("Sound") then
					continue
				end

				Sound.Volume = Request.Value
			end

			return Request.Value
		end,
	},
	
	{
		Name = "Panel smoothness",
		Type = "Slider",

		Description = "Smoothness of dragging the panel (Lower = smoother).",
		Default = {
			Default = 0.8,
			Min = 0,
			Max = 1,
			Slide = .1,
		},

		LoadData = function(self, Settings)
			self.Default.Default = Settings.UISmoothness
		end,

		SaveData = function(self, Request, Settings)
			Settings.UISmoothness = Request.Value
			return Settings
		end,

		Callback = function(Request)
			if not _G.GAdmin.Framework then
				repeat
					task.wait()
				until _G.GAdmin.Framework
			end
			
			_G.GAdmin.Framework.Draggable.Smoothness = Request.Value
		end,
	},
	
	{
		Name = "Prefix",
		Type = "Text",

		Description = "Sets chat command prefix.",
		Default = ";",

		LoadData = function(self, Settings, Session)
			self.Default = Session.Prefix
		end,

		SaveData = function(self, Request, Settings)
			return Settings, {"Prefix", Request.Value}
		end,

		Callback = function(Request)
			if type(Request.Value) ~= "string" then
				Request.Object.Input.Text = Request.OldValue
				return Request.OldValue
			end
			
			local Prefix = Request.Value:sub(1, 3)
			Request.Object.Input.Text = Prefix
			return Prefix
		end,
	},
	
	{
		Name = "Delay Load",
		Type = "Text",

		Description = "Waits given number of seconds before booting up panel.",
		Default = "",

		LoadData = function(self, Settings)
			self.Default = tostring(Settings.LoadDelay)
		end,

		SaveData = function(self, Request, Settings)
			Settings.LoadDelay = tonumber(Request.Value)
			return Settings
		end,

		Callback = function(Request)
			local Value = tonumber(Request.Value:sub(1, 8))
			if not Value then
				Request.Object.Input.Text = Request.OldValue
				return Request.OldValue
			end
			
			return Request.Value
		end,
	},
	
	{
		Name = "Ban message",
		Type = "Text",

		Description = "Will set ban message to given one if none was given.",
		Default = "No reason.",

		LoadData = function(self, Settings, Session)
			self.Default = Session.Defaults.BanMessage
		end,

		SaveData = function(self, Request, Settings, Session)
			Session.Defaults.BanMessage = Request.Value
			return Settings, {"Defaults", Session.Defaults}
		end,

		Callback = function(Request)
			if not Request.Value then
				Request.Object.Input.Text = Request.OldValue
				return Request.OldValue
			end

			local String = Remote:Fire("Filter", Request.Value:sub(1, 35))
			Request.Object.Input.Text = String
			return String
		end,
	},
	
	{
		Name = "Kick message",
		Type = "Text",

		Description = "Will set kick message to given one if none was given.",
		Default = "No reason.",

		LoadData = function(self, Settings, Session)
			self.Default = Session.Defaults.KickMessage
		end,

		SaveData = function(self, Request, Settings, Session)
			Session.Defaults.KickMessage = Request.Value
			return Settings, {"Defaults", Session.Defaults}
		end,

		Callback = function(Request)
			if not Request.Value then
				Request.Object.Input.Text = Request.OldValue
				return Request.OldValue
			end

			local String = Remote:Fire("Filter", Request.Value:sub(1, 35))
			Request.Object.Input.Text = String
			return String
		end,
	},
	
	{
		Name = "UI Size",
		Type = "Slider",

		Description = "Size of this UI Panel.",
		Default = {
			Default = 1,
			Min = 1,
			Max = 1.5,
			Slide = .1,
		},

		LoadData = function(self, Settings)
			self.Default.Default = Settings.UISize
		end,

		SaveData = function(self, Request, Settings)
			Settings.UISize = Request.Value
			return Settings
		end,

		Callback = function(Request)
			local Value = Request.Value
			task.delay(1, function()
				if Request.Value ~= Value then
					return
				end
				
				UI.Gui.MainFrame.PanelSize.Scale = Request.Value
			end)
			
			return Request.Value
		end,
	},
	
	{
		Name = "UI Theme",
		Type = "Color",

		Description = "Theme of the panel.",
		Default = {
			Default = "#0b132b",
			Color = "#0b132b"
		},

		LoadData = function(self, Settings)
			self.Default.Default = Settings.UITheme.Color
		end,

		SaveData = function(self, Request, Settings)
			Settings.UITheme.Color = Request.Value
			return Settings
		end,

		Callback = function(Request, Settings)
			local Value = Request.Value
			local H, S, V = Color3.fromHex(Value):ToHSV()
			
			local Hue = Configuration.ThemeUsage.Hue and H or nil
			local Saturation = Configuration.ThemeUsage.Saturation and S or nil
			local Value = Configuration.ThemeUsage.Value and V or nil
			
			if not Hue and not Saturation and not Value then
				Hue = H
			end
			
			_G.GAdmin.Theme = {
				Hue = Hue,
				Saturation = Saturation,
				Value = Value
			}
			
			if not _G.GAdmin.UseTheme then
				return Request.Value
			end
			
			UI:SetTheme(Hue, Saturation, Value)
			return Request.Value
		end,
	},

	{
		Name = "Use Theme",
		Type = "Boolean",

		Description = "Use picked theme.",
		Default = false,

		LoadData = function(self, Settings)
			self.Default = Settings.UITheme.Enabled
			_G.GAdmin.UseTheme = self.Default
		end,

		SaveData = function(self, Request, Settings)
			Settings.UITheme.Enabled = Request.Value
			return Settings
		end,

		Callback = function(Request)
			local Value = Request.Value
			_G.GAdmin.UseTheme = Value
			
			if Value and _G.GAdmin.Theme then
				UI:SetTheme(_G.GAdmin.Theme.Hue, _G.GAdmin.Theme.Saturation, _G.GAdmin.Theme.Value)
				return Request.Value
			end
			
			if Value then
				UI:RefreshTheme()
				return Request.Value
			end
			
			UI:ClearTheme()
			return Request.Value
		end,
	},
}

return {
	Settings = Settings
}