--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Configuration = require(Main.Settings.Interface)
local SearchFramework = require(Main.Client.Services.Framework.Search)
--==

local Place = {}
Place.Name = "_PlayerStatsPicker"
Place.Previous = {
	Place = "Statistics",
	Page = 1,
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Pages = {
		["1"] = function(self, UI, Page, Interface)
			UI.MainFrame.Top.Title.Text = "Players"
			self.Arguments.Search:Clear()
		end,
	}
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	_G.GAdmin.Scheduler:Insert("Global", "StatsRefresh", function()
		self.Arguments.DebounceReload = tick()
		self:RefreshPlayers(UI, Page, Interface)
	end, Configuration.StatsRefresh)
	
	self.Arguments.Search = SearchFramework.new(Page.List)
	self.Arguments.Search:SetTemplate(Page.Search)
	
	Frame.Pages["1"].Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Frame.Pages["1"].Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceReload and tick() - self.Arguments.DebounceReload < 2 then
			return
		end

		self.Arguments.DebounceReload = tick()
		self:RefreshPlayers(UI, Page, Interface)
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Pages[Page.Name](self, UI, Page, Interface)
end

function Place:RefreshPlayers(UI, Page, Interface)
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Items = {}
	for i, player in ipairs(Players:GetPlayers()) do
		local Success, Avatar = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		
		local Template = GuiAssets.PlayerCard:Clone()
		Template.Name = `{player.Name}-{player.UserId}`
		
		Template.Username.Username.Text = `@{player.Name}`
		Template.DisplayName.DisplayName.Text = player.DisplayName
		
		Template.Avatar.Image = Success and Avatar or ""
		Template.Avatar.Error.Visible = not Success
		
		Template.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)
		
		Template.Interact.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			Interface:Refresh({
				Place = "_PlayerStats",
				Page = 1,
				MaxPages = 1,
				Arguments = {
					User = player.UserId,
				},
			})
		end)
		
		Template.Parent = Page.List
		table.insert(Items, {
			Frame = Template.Name,
			Search = {player.UserId, `@{player.Name}`, player.DisplayName}
		})
	end
	
	self.Arguments.Search.Items = Items
	self.Arguments.Search:Search(self.Arguments.Search.Current or "")
end

return Place