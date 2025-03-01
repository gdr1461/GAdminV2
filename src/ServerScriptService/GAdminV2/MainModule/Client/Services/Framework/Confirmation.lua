--== << Services >>
local GAdminShared = script:FindFirstAncestor("GAdminShared")
local Sound = require(GAdminShared.Shared.Services.Sound)
local UI = require(GAdminShared.Client.Services.UI).Gui

local Assets = GAdminShared.Shared.Assets
local GuiAssets = Assets.Gui
--==

local Window = {}
Window.__type = "GAdmim Window"
Window.__index = Window

function Window:Update()
	if not self.Window or not self.Window.Parent then
		return
	end
	
	self.Window.MainFrame.Description.Scrollable.Description.Text = self.Description
	if self.Frame.Visible and self.Page.Visible then
		return
	end
	
	self:Callback(false)
	self:Destroy()
end

function Window:Destroy()
	for i, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	
	if self.Window then
		self.Window:Destroy()
	end
	
	setmetatable(self, nil)
	table.clear(self)
	self.Destroyed = true
end

return {
	new = function(Data)
		Data = Data or {}
		Data.Place = Data.Place or "Main"
		Data.Page = Data.Page or 1
		
		Data.Description = Data.Description or "N/A"
		Data.Callback = Data.Callback or function() end
		
		local PlaceFrame = UI.MainFrame.Places:FindFirstChild(Data.Place)
		if not PlaceFrame then
			warn(`[GAdmin Window]: Place '{Data.Place}' is invalid.`)
			return
		end
		
		local PageFrame = PlaceFrame.Pages:FindFirstChild(Data.Page)
		if not PageFrame then
			warn(`[GAdmin Window]: Page {Data.Page} of place '{Data.Place}' is invalid.`)
			return
		end
		
		local Confirmation = setmetatable({}, Window)
		Confirmation.Connections = {}
		
		Confirmation.Data = Data
		Confirmation.Frame = PlaceFrame
		Confirmation.Page = PageFrame
		
		Confirmation.Description = Data.Description
		Confirmation.Callback = Data.Callback
		
		Confirmation.Window = GuiAssets.Confirmation:Clone()
		Confirmation.Window.Parent = PageFrame
		Confirmation.Window.Visible = true
		
		table.insert(Confirmation.Connections, Confirmation.Window.MainFrame.Confirm.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end))
		
		table.insert(Confirmation.Connections, Confirmation.Window.MainFrame.Confirm.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			Confirmation.Window:Destroy()
			Confirmation:Callback(true)
			
			if Confirmation.Destroyed then
				return
			end
			
			Confirmation:Destroy()
		end))
		
		table.insert(Confirmation.Connections, Confirmation.Window.MainFrame.Decline.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end))
		
		table.insert(Confirmation.Connections, Confirmation.Window.MainFrame.Decline.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			Confirmation.Window:Destroy()
			Confirmation:Callback(false)
			
			if Confirmation.Destroyed then
				return
			end
			
			Confirmation:Destroy()
		end))
		
		table.insert(Confirmation.Connections, _G.GAdmin.Render(function()
			Confirmation:Update()
		end))
		
		return Confirmation
	end,
}