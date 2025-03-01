--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Settings = require(Main.Settings.Interface)
local Remote = require(Main.Shared.Services.Remote)
--==

local Place = {}
Place.Name = "_Logs"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Type = "Logs",
	Logs = {},
}

function Place:Load(UI, Frame, Interface)
	_G.GAdmin.Scheduler:Insert("Global", "LogRefreshClient", function()
		self.Arguments.DebounceLogs = tick()
		self:ReloadLogs(Frame, Interface)
	end, Settings.LogRefresh)
	
	local Page = Frame.Pages["1"]
	Page.Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceLogs and tick() - self.Arguments.DebounceLogs < 2 then
			return
		end

		self.Arguments.DebounceLogs = tick()
		self:ReloadLogs(Frame, Interface)
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Type = Arguments.Type
	UI.MainFrame.Top.Title.Text = Arguments.Type
	self:ReloadLogs(Frame, Interface)
end

function Place:ReloadLogs(Frame, Interface)
	local Page = Frame.Pages["1"]
	self.Arguments.Logs = Remote:Fire("GetLogs", self.Arguments.Type) or {}
	
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end
	
	if not self.Arguments.Logs then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Page hasn't been loaded.`
		return
	end
	
	if #self.Arguments.Logs <= 0 then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `No logs were found.`
		return
	end
	
	Page.Error.Visible = false
	local ImageCache = {}
	
	for i, Log in ipairs(self.Arguments.Logs) do
		local ImageSuccess, Image = pcall(function()
			ImageCache[Log.UserId] = ImageCache[Log.UserId] or game.Players:GetUserThumbnailAsync(Log.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			return ImageCache[Log.UserId]
		end)
		
		local Time = DateTime.fromUnixTimestamp(Log.Time):FormatLocalTime("HH:mm", "en-us")
		local Frame = GuiAssets.Log:Clone()
		
		Frame.Scrollable.Message.Text = Log.Message
		Frame.Time.Text = Time
		
		Frame.Avatar.Error.Visible = not ImageSuccess
		Frame.Avatar.Image = Image
		
		Frame.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)
		
		Frame.Interact.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			for i, Frame in ipairs(Page.List:GetChildren()) do
				if not Frame:IsA("Frame") then
					continue
				end

				Frame:Destroy()
			end
			
			Interface:Refresh({
				Place = "_PlayerStats",
				Back = "Main",

				Page = 1,
				MaxPages = 1,
				Arguments = {
					User = Log.UserId
				}
			})
		end)
		
		Frame.LayoutOrder = -i
		Frame.Parent = Page.List
	end
end

return Place