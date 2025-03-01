--== << Services >>

local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Settings = require(Main.Settings.Main)
local Configuration = require(Main.Settings.Interface)

local Remote = require(Main.Shared.Services.Remote)
local Ranks = require(Main.Settings.Ranks)

local RankService = require(Main.Shared.Services.Rank)
local Restrictions = require(Main.Settings.Restrictions)

local RChangeRanks = RankService:Find(Restrictions.Ranks.ChangeRanks)
local RServerRanked = RankService:Find(Restrictions.Ranks.ServerRankedUsers)

local RChangeBanlist = {
	Server = RankService:Find(Restrictions.Ranks.ChangeBanlistServer),
	Global = RankService:Find(Restrictions.Ranks.ChangeBanlistGlobal),
}

local RBanlist = RankService:Find(Restrictions.Ranks.Banlist)
local Cache = require(Main.Client.Services.Framework.Cache)

local ConfirmationConstructor = require(Main.Client.Services.Framework.Confirmation)
local SearchFramework = require(Main.Client.Services.Framework.Search)
local UIService = require(Main.Client.Services.UI)

--==

local Place = {}
Place.Name = "Ranks"
Place.Previous = {
	Place = "Server",
	Page = 1
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	BanActions = {}
}

Place.Pages = {
	--== Global ranks
	[1] = function(self, UI, Frame, Page, Interface)
		UI.MainFrame.Top.Title.Text = "Global Ranks"
		local HasPermission = Cache.Session.Rank >= RChangeRanks.Rank
		Page.Add.Visible = HasPermission
		
		Page.Reload.Position = HasPermission and UDim2.fromScale(.083, 0) or Page.Add.Position
		self.Arguments.Search:Clear()
	end,
	
	--== Server ranks
	[2] = function(self, UI, Frame, Page, Interface)
		UI.MainFrame.Top.Title.Text = "Server Ranks"
	end,
	
	--== Banlist
	[3] = function(self, UI, Frame, Page, Interface)
		UI.MainFrame.Top.Title.Text = "Banlist"
		Page.List.Interactable = true
		Page.Reload.Interactable = true
		Page.Actions.Visible = false
		
		self.Arguments.Unbanning = false
		self.Arguments.BanActions = {}
	end,
}

function Place:Load(UI, Frame, Interface)
	task.wait()
	_G.GAdmin.Scheduler:Insert("Global", "RefreshRanks", function()
		self.Arguments.DebounceGlobal = tick()
		self:RefreshRanks(UI, Frame, Interface)
	end, Configuration.RankRefresh)
	
	_G.GAdmin.Scheduler:Insert("Global", "RefreshServerRanks", function()
		self.Arguments.DebounceServer = tick()
		self:RefreshServerRanks(UI, Frame, Interface)
	end, Configuration.ServerRankRefresh)
	
	_G.GAdmin.Scheduler:Insert("Global", "RefreshBanlistClient", function()
		self.Arguments.DebounceBanlist = tick()
		self:RefreshBanlist(UI, Frame, Interface)
	end, Configuration.BanlistRefresh)
	
	self.Arguments.Search = SearchFramework.new(Frame.Pages["1"].List)
	self.Arguments.Search:SetTemplate(Frame.Pages["1"].Search)

	Frame.Pages["1"].Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Frame.Pages["1"].Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceGlobal and tick() - self.Arguments.DebounceGlobal < 2 then
			return
		end
		
		self.Arguments.DebounceGlobal = tick()
		self:RefreshRanks(UI, Frame, Interface)
	end)
	
	Frame.Pages["1"].Add.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Frame.Pages["1"].Add.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if Settings.ConstantRanks then
			Interface.Popup:New({
				Type = "Warning",
				Text = "Constant ranks is enabled."
			})
			
			return
		end
		
		Interface:SetLocation("_RankEditor", 1)
	end)
	
	Frame.Pages["2"].Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Frame.Pages["2"].Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceServer and tick() - self.Arguments.DebounceServer < 2 then
			return
		end
		
		self.Arguments.DebounceServer = tick()
		self:RefreshServerRanks(UI, Frame, Interface)
	end)
	
	Frame.Pages["3"].Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Frame.Pages["3"].Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceBanlist and tick() - self.Arguments.DebounceBanlist < 2 then
			return
		end

		self.Arguments.DebounceBanlist = tick()
		self:RefreshBanlist(UI, Frame, Interface)
	end)
	
	Frame.Pages["3"].Actions.MainFrame.Close.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Frame.Pages["3"].Actions.MainFrame.Close.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self.Arguments.Unbanning = false
		self.Arguments.BanActions = {}
		
		Frame.Pages["3"].List.Interactable = true
		Frame.Pages["3"].Actions.Visible = false
		Frame.Pages["3"].Reload.Interactable = true
	end)
	
	Frame.Pages["3"].Actions.MainFrame.Unban.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Frame.Pages["3"].Actions.MainFrame.Unban.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.Unbanning or not self.Arguments.BanActions.User then
			return
		end

		self.Arguments.Unbanning = true
		Frame.Pages["3"].Actions.Visible = false
		
		local Confirmation = ConfirmationConstructor.new({
			Place = self.Name,
			Page = 3,
			
			Description = `Are you sure you want to unban player <font color="#ffbfaa">{self.Arguments.BanActions.User.Name}</font>? This action can't be undone.`,
			Callback = function(Confirmation, Confirmed)
				if not Confirmed then
					self.Arguments.Unbanning = false
					Frame.Pages["3"].Actions.Visible = true
					return
				end
				
				UIService:SetLoading(UI.MainFrame, function()
					return not self.Arguments.Unbanning or not Frame.Pages["3"].Visible
				end)
				
				local Success, Response = Remote:Fire("Unban", self.Arguments.BanActions.User.Id, self.Arguments.BanActions.Data.Type)
				self.Arguments.Unbanning = false
				
				Frame.Pages["3"].Actions.Visible = false
				Frame.Pages["3"].Reload.Interactable = true
				
				if not Success then
					Interface.Popup:New({
						Type = "Error",
						Text = Response or "An unexpected error occurred. Please, try again later.",
						Time = 20,
					})
					
					return
				end
				
				Interface.Popup:New({
					Type = "Notice",
					Text = `User <font color="#ffbfaa">{self.Arguments.BanActions.User.Name}</font> is successfuly unbanned.`,
					Time = 20,
				})
			end,
		})
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Pages[tonumber(Page.Name, 10)](self, UI, Frame, Page, Interface)
end

function Place:RefreshRanks(UI, Frame, Interface)
	RankService:Reload()
	for i, Frame in ipairs(Frame.Pages["1"].List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Items = {}
	for i, Rank in ipairs(Ranks.Ranks) do	
		local UserCount = #RankService:GetUsers(Rank.Name)
		local Template = GuiAssets.Rank:Clone()

		Template.Name = Rank.Name
		Template.Title.Scrollable.Title.Text = Rank.Name
		Template.Rank.Rank.Text = `Rank: {Rank.Rank}`
		Template.Players.Scrollable.Players.Text = `Users: {UserCount}`

		Template.LayoutOrder = -(Rank.Rank * 1000 + math.min(UserCount, 100))
		Template.Parent = Frame.Pages["1"].List

		Template.Interact.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			Interface:Refresh({
				Place = "_Rank",
				Page = 1,
				MaxPages = 1,
				Arguments = {
					Rank = Rank.Name
				}
			})
		end)
		
		table.insert(Items, {
			Frame = Rank.Name,
			Search = {Rank.Name, Rank.Rank}
		})
	end
	
	self.Arguments.Search.Items = Items
	self.Arguments.Search:Search(self.Arguments.Search.Current or "")
end

function Place:RefreshServerRanks(UI, Frame, Interface)
	local Page = Frame.Pages["2"]
	local Players = Remote:Fire("GetPlayers")
	
	Page.Error.Visible = false
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("TextButton") then
			continue
		end
		
		Frame:Destroy()
	end
	
	if RServerRanked.Rank > Cache.Session.Rank then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Rank <font color="#ffbfaa">{RServerRanked.Name}+</font> required.`
		return
	end
	
	if not Players then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Page hasn't been loaded.`
		return
	end
	
	for UserId, UserData in pairs(Players) do
		local Rank = RankService:Find(UserData.Data.Rank)
		local Template = UIService:CreatePlayer(GuiAssets.FlexPlayer, UserId, `[<font color="#{Rank.Color}">{Rank.Name}</font>] %s`)

		Template.LayoutOrder = Rank.Rank * 10000
		Template.Parent = Page.List
	end
end

function Place:RefreshBanlist(UI, Frame, Interface)
	local Page = Frame.Pages["3"]
	Cache.Banlist = Remote:Fire("GetBanlist") or {}
	
	Page.List.Interactable = true
	Page.Reload.Interactable = true
	Page.Actions.Visible = false

	self.Arguments.Unbanning = false
	self.Arguments.BanActions = {}
	
	Page.Error.Visible = false
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("TextButton") then
			continue
		end

		Frame:Destroy()
	end
	
	if RBanlist.Rank > Cache.Session.Rank then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Rank <font color="#ffbfaa">{RBanlist.Name}+</font> required.`
		return
	end

	if not Cache.Banlist then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Page hasn't been loaded.`
		return
	end
	
	local Banlist = {}
	for UserId, BanData in pairs(Cache.Banlist) do
		table.insert(Banlist, {
			User = UserId,
			Data = BanData
		})
	end
	
	if #Banlist <= 0 then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = `Banlist is empty.`
		return
	end
	
	for i, Ban in ipairs(Banlist) do
		local UserId = tonumber(Ban.User)
		local ModeratorId = tonumber(Ban.Data.Moderator)
		
		local BanData = _G.GAdmin.__GetBanData(Ban.Data)
		local Template = UIService:CreatePlayer(GuiAssets.BannedPlayer, UserId, "%s")
		Template.Parent = Page.List
		
		Template.Reason.Reason.Text = `Reason: '{BanData.Reason}'`
		Template.Navigation.Visible = Cache.Session.Rank >= RChangeBanlist[BanData.Type or "Global"].Rank
		
		Template.Navigation.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			Frame.Pages["3"].List.Interactable = false
			self:SetBanActions(Page, UserId, BanData)
		end)
	end
end

function Place:SetBanActions(Page, UserId, BanData)
	local Frame = Page.Actions.MainFrame
	local NameSuccess, Username = pcall(function()
		return game.Players:GetNameFromUserIdAsync(UserId)
	end)
	
	local ImageSuccess, Image = pcall(function()
		return game.Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	
	local ModId = tonumber(BanData.Moderator)
	local ModSuccess, ModName = pcall(function()
		return game.Players:GetNameFromUserIdAsync(ModId)
	end)
	
	Username = NameSuccess and Username or "N/A"
	Image = ImageSuccess and Image or ""
	ModName = ModSuccess and ModName or "N/A"
	
	local OnDate = DateTime.fromUnixTimestamp(tonumber(BanData.On or "0"))
	local UntilDate = DateTime.fromUnixTimestamp(tonumber(BanData.Time or "0"))
	
	self.Arguments.BanActions = {
		User = {
			Id = UserId,
			Name = Username,
			Avatar = Image
		},
		
		Moderator = {
			Id = ModId,
			Name = ModName,
		},
		
		Dates = {
			On = OnDate,
			Until = UntilDate,
		},
		
		Data = BanData
	}
	
	-- Setting user.
	Frame.User.UserId.UserId.Text = `UserId: {UserId}`
	Frame.User.Username.Username.Text = Username
	
	Frame.User.Avatar.Error.Visible = not ImageSuccess
	Frame.User.Avatar.Image = Image
	
	-- Setting parameters.
	Frame.Parameters.List.Moderator.Text = `Mod: {ModName}`
	Frame.Parameters.List.Reason.Text = `Reason: {BanData.Reason}`
	Frame.Parameters.List.PrivateReason.Text = `ModHint: {BanData.PrivateReason or "N/A"}`
	
	Frame.Parameters.List.On.Text = `On: {OnDate:FormatLocalTime("HH:mm:ss LL", "en-us")}`
	Frame.Parameters.List.Time.Text = `Until: {UntilDate:FormatLocalTime("HH:mm:ss LL", "en-us")}`
	Page.Actions.Visible = true
end

return Place