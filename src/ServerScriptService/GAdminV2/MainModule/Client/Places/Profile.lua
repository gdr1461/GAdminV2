--== << Services >>
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Cache = require(Main.Client.Services.Framework.Cache)
local RankService = require(Main.Shared.Services.Rank)
--==

local Place = {}
Place.Name = "Profile"
Place.Previous = {
	Place = "Server",
	Page = 1
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	Page.Statistics.Interact.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Statistics.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		Interface:Refresh({
			Place = "_PlayerStats",
			Back = "Statistics",
			
			Page = 1,
			MaxPages = 1,
			Arguments = {
				User = player.UserId
			}
		})
	end)
	
	Page.About.Interact.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Page.About.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		Interface:SetLocation("About")
	end)
end

function Place:Reload(Page, Interface)
	Page.Username.Scrollable.Username.Text = player.Name
	Page.UserId.Scrollable.UserId.Text = `ID: {player.UserId}`
	
	local Success, Headshot = pcall(function()
		return game.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	
	Page.Avatar.Error.Visible = not Success
	Page.Avatar.Image = Success and Headshot or ""
	
	local Rank = RankService:Find(Cache.Session.Rank)
	local Color = Rank.Color:gsub("#", "")
	Page.Rank.Scrollable.Rank.Text = `Rank: [<font color="#{Color}">{Rank.Name}</font>] <font color="#b3b3b3" size="19">/ {Rank.Rank}</font>`
end

return Place