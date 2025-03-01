--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Settings = require(Main.Client.Services.Framework.Settings)
local UIService = require(Main.Client.Services.UI)
--==

local Place = {}
Place.Name = "Settings"
Place.Previous = {
	Place = "Main",
	Page = 1
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	Settings:Reload()
	
	Frame.Pages["1"].Save.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Frame.Pages["1"].Save.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Busy or (self.Debounce and tick() - self.Debounce < 2) then
			return
		end

		self.Busy = true
		UIService:SetLoading(UI.MainFrame, function()
			return not self.Busy or not Frame.Pages["1"].Visible
		end)
		
		Settings:Save()
		self.Debounce = tick()
		self.Busy = false
		
		Interface.Popup:New({
			Type = "Notice",
			Text = "Settings saved."
		})
	end)
end

return Place