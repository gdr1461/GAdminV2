--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")
local Shared = Main.Shared

local Sound = require(Shared.Services.Sound)
local Rank = require(Shared.Services.Rank)
local Remote = require(Shared.Services.Remote)

local Cache = require(Main.Client.Services.Framework.Cache)
local Graph = require(Main.Client.Services.Graph)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
--==

local Place = {}
Place.Name = "_PlayerStats"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Graphs = {},
	Requests = {},
	CommandUsage = {},
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	local Resolution = 25
	
	local Theme = {
		LightBackground = Color3.new(0.0431373, 0.0745098, 0.168627),
		Background = Color3.new(0.145098, 0.192157, 0.333333),
		Text = Color3.new(1, 1, 1)
	}
	
	self.Arguments.Graphs.Requests = Graph.new(Page.List.Requests)
	self.Arguments.Graphs.Command = Graph.new(Page.List.Command)
	
	self.Arguments.Graphs.Requests.Resolution = Resolution
	self.Arguments.Graphs.Command.Resolution = Resolution
	
	self.Arguments.Graphs.Requests.Theme(Theme)
	self.Arguments.Graphs.Command.Theme(Theme)
	
	local Calls = 0
	_G.GAdmin.Scheduler:Insert("Global", "SessionJoinRefresh", function()
		if not self.Arguments.User then
			return
		end

		local Session = tick() - self.Arguments.SessionJoin
		local Hours = string.format("%02d", math.floor(Session / 3600))
		local Minutes = string.format("%02d", math.floor(Session % 3600 / 60))
		local Seconds = string.format("%02d", math.floor(Session % 60))

		Page.List.Session.Scrollable.Session.Text = `Session: <font color="#a9a9a9">{Hours}:{Minutes}:{Seconds}</font>`
		Calls += 1

		if Calls % 61 ~= 0 then
			return
		end

		self:Update(UI, Page, Interface)
	end, 1)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	local User = Players:GetPlayerByUserId(Arguments.User)
	if not User then
		warn(`[GAdmin Interface]: _PlayerStats :: Player with id '{Arguments.User}' is not online.`)
		return
	end
	
	UI.MainFrame.Top.Title.Text = "Player Stats"
	Page.List.CanvasPosition = Vector2.new()
	
	self.Arguments.User = User
	self:Update(UI, Page, Interface)
end

function Place:Update(UI, Page, Interface)
	local Data = Remote:Fire("GetPlayer", self.Arguments.User.UserId)
	if not Data then
		return
	end
	
	local User = self.Arguments.User
	local Age = User.AccountAge
	
	self.Arguments.SessionJoin = Data.Session.SessionJoin
	local Creation = DateTime.fromUnixTimestamp(os.time() - (Age * 86400))
	
	local Success, Avatar = pcall(function()
		return Players:GetUserThumbnailAsync(User.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	
	Page.List.User.Username.Username.Text = `{User.DisplayName} (@{User.Name})`
	Page.List.User.UserId.UserId.Text = `UserId: {User.UserId}`
	
	Page.List.User.Avatar.Image = Success and Avatar or ""
	Page.List.User.Avatar.Error.Visible = not Success
	
	Page.List.Age.Scrollable.Age.Text = `Account age: <font color="#a9a9a9">{Age} days</font>`
	Page.List.Creation.Scrollable.Creation.Text = `Account creation: <font color="#a9a9a9">{Creation:FormatLocalTime("DD/MM/YYYY", "en-us")}</font>`
	
	table.insert(Data.Session.Requests, 1, 0)
	table.insert(Data.Session.CommandUsage, 1, 0)
	
	self.Arguments.Graphs.Requests.Data = {
		["Requests Per Minute"] = Data.Session.Requests
	}
	
	self.Arguments.Graphs.Command.Data = {
		["Commands Per Minute"] = Data.Session.CommandUsage
	}
end

return Place