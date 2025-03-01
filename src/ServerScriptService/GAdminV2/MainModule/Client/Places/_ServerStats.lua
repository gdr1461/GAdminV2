--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Graph = require(Main.Client.Services.Graph)
local Remote = require(Main.Shared.Services.Remote)
--==

local Place = {}
Place.Name = "_ServerStats"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Enabled = true,
	Graphs = {},
	PlayerCount = {0}
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	self.Arguments.Graphs.PlayerCount = Graph.new(Page.List.PlayerCount)
	
	self.Arguments.Graphs.PlayerCount.Resolution = 25
	self.Arguments.Graphs.PlayerCount.Theme({
		LightBackground = Color3.new(0.0431373, 0.0745098, 0.168627),
		Background = Color3.new(0.145098, 0.192157, 0.333333),
		Text = Color3.new(1, 1, 1)
	})
	
	Players.PlayerAdded:Connect(function()
		Page.List.TotalPlayers.Scrollable.Count.Text = `Players: <font color="#a9a9a9">{#Players:GetPlayers()}</font>`
		Page.List.MaxPlayers.Scrollable.Count.Text = `Max Players: <font color="#a9a9a9">{Players.MaxPlayers}</font>`
	end)
	
	Players.PlayerRemoving:Connect(function()
		Page.List.TotalPlayers.Scrollable.Count.Text = `Players: <font color="#a9a9a9">{#Players:GetPlayers()}</font>`
		Page.List.MaxPlayers.Scrollable.Count.Text = `Max Players: <font color="#a9a9a9">{Players.MaxPlayers}</font>`
	end)
	
	task.defer(function()
		local function Update()
			table.insert(self.Arguments.PlayerCount, #Players:GetPlayers())
			self:Update(UI, Page, Interface)
		end
		
		local Calls = 0
		Update()
		
		while self.Arguments.Enabled do
			task.wait(1)
			Calls += 1
			
			if Calls % 60 == 0 then
				Update()
				continue
			end
			
			local Uptime = workspace.DistributedGameTime
			local Hours = string.format("%02d", math.floor(Uptime / 3600))
			local Minutes = string.format("%02d", math.floor(Uptime % 3600 / 60))
			local Seconds = string.format("%02d", math.floor(Uptime % 60))
			Page.List.Uptime.Scrollable.Uptime.Text = `Server uptime: <font color="#a9a9a9">{Hours}:{Minutes}:{Seconds}</font>`
		end
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	UI.MainFrame.Top.Title.Text = `Server Stats`
	Page.List.CanvasPosition = Vector2.new()
	self:Update(UI, Page, Interface)
end

function Place:Update(UI, Page, Interface)
	Page.List.TotalPlayers.Scrollable.Count.Text = `Players: <font color="#a9a9a9">{#Players:GetPlayers()}</font>`
	Page.List.MaxPlayers.Scrollable.Count.Text = `Max Players: <font color="#a9a9a9">{Players.MaxPlayers}</font>`
	Page.List.FPS.Scrollable.FPS.Text = `Physics FPS: <font color="#a9a9a9">{workspace:GetRealPhysicsFPS()}</font>`
	
	self.Arguments.Graphs.PlayerCount.Data = {
		Count = self.Arguments.PlayerCount
	}
	
	for i, Frame in ipairs(Page.List.ActivePlayers.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local ActivePlayers = self:GetActivePlayers(3)
	for i, player in ipairs(ActivePlayers) do
		local Success, Avatar = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		
		local Card = GuiAssets.PlayerCard:Clone()
		Card.DisplayName.DisplayName.Text = player.DisplayName
		Card.Username.Username.Text = `@{player.Name}`
		
		Card.Avatar.Image = Success and Avatar or ""
		Card.Avatar.Error.Visible = not Success
		
		Card.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)

		Card.Interact.Activated:Connect(function()
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
		
		Card.LayoutOrder = i
		Card.Parent = Page.List.ActivePlayers.List
	end
	
	local Uptime = workspace.DistributedGameTime
	local Hours = string.format("%02d", math.floor(Uptime / 3600))
	local Minutes = string.format("%02d", math.floor(Uptime % 3600 / 60))
	local Seconds = string.format("%02d", math.floor(Uptime % 60))
	Page.List.Uptime.Scrollable.Uptime.Text = `Server uptime: <font color="#a9a9a9">{Hours}:{Minutes}:{Seconds}</font>`
end

function Place:GetActivePlayers(Amount)
	Amount = Amount or 3
	local PlayerDatas = Remote:Fire("GetPlayers")
	
	if not PlayerDatas then
		return
	end
	
	local ActivePlayers = {}
	table.sort(PlayerDatas, function(Data1, Data2)
		local Amount1 = Data1.Session.Requests[#Data1.Session.Requests] + Data1.Session.CommandUsage[#Data1.Session.CommandUsage]
		local Amount2 = Data2.Session.Requests[#Data2.Session.Requests] + Data2.Session.CommandUsage[#Data2.Session.CommandUsage]
		
		return Amount2 > Amount1
	end)
	
	local Count = 0
	for UserId, PlayerData in pairs(PlayerDatas) do
		Count += 1
		if Count >= Amount then
			break
		end
		
		local Success, Player = pcall(function()
			return Players:GetPlayerByUserId(tonumber(UserId))
		end)
		
		if not Success then
			continue
		end
		
		table.insert(ActivePlayers, Player)
	end
	
	return ActivePlayers
end

return Place