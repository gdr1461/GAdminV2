--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("GAdminShared")
local Shared = Main.Shared

local Cache = require(Main.Client.Services.Framework.Cache)
local Sound = require(Shared.Services.Sound)

local UIService = require(Main.Client.Services.UI)
local Remote = require(Shared.Services.Remote)

local ConfirmationConstructor = require(Main.Client.Services.Framework.Confirmation)
local RankService = require(Shared.Services.Rank)

local Restrictions = require(Main.Settings.Restrictions)
local RGlobalRanked = RankService:Find(Restrictions.Ranks.GlobalRankedUsers)
local RChangeRanks = RankService:Find(Restrictions.Ranks.ChangeRanks)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
--==

local Place = {}
Place.Name = "_Rank"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Busy = false,
	Thread = nil
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	Page.Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.Debounce and tick() - self.Arguments.Debounce < 2 then
			return
		end
		
		self:RefreshUsers(UI, Frame, Interface)
	end)
	
	Page.ChangeRank.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.ChangeRank.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.Busy then
			return
		end
		
		if Cache.Session.Rank < RChangeRanks.Rank then
			Interface.Popup:New({
				Type = "Error",
				Text = `Rank '{RChangeRanks.Name}+' required`,
				Time = 10
			})

			return
		end
		
		local RankData = table.clone(self.Arguments.Rank)
		RankData.Players = {}

		for i, UserLike in ipairs(self.Arguments.Rank.Players) do
			local UserId = tonumber(UserLike)
			local Name 
			
			if UserId then
				local Success, PlayerName = pcall(function()
					return Players:GetNameFromUserIdAsync(UserId)
				end)
				
				Name = Success and PlayerName or "N/A"
			else
				Name = UserLike
			end
			
			table.insert(RankData.Players, Name)
		end
		
		Interface:Refresh({
			Place = "_RankEditor",
			Page = 1,
			MaxPages = 1,
			Arguments = {
				Rank = RankData,
				Action = "Change",
			}
		})
	end)
	
	Page.RemoveRank.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.RemoveRank.Activated:Connect(function()
		if self.Arguments.Busy then
			return
		end
		
		Sound:Play("Buttons", "Click1")
		if Cache.Session.Rank < RChangeRanks.Rank then
			Interface.Popup:New({
				Type = "Error",
				Text = `Rank '{RChangeRanks.Name}+' required`,
				Time = 10
			})
			
			return
		end
		
		self.Arguments.Busy = true
		if self.Arguments.Confirmation and not self.Arguments.Confirmation.Destroyed then
			self.Arguments.Confirmation:Destroy()
		end
		
		self.Arguments.Confirmation = ConfirmationConstructor.new({
			Place = self.Name,
			Page = 1,
			
			Description = `Are you sure you want to remove rank '<font color="#ffbfaa">{self.Arguments.Rank.Name}</font>'? This action can't be undone.`,
			Callback = function(Confirmation, Confirmed)
				if not Confirmed then
					self.Arguments.Busy = false
					return
				end
				
				UIService:SetLoading(UI.MainFrame, function()
					return not self.Arguments.Busy or not Frame.Pages["1"].Visible
				end)
				
				local Response = Remote:Fire("SetRank", "Remove", self.Arguments.Rank.Name, false)
				if Response[1] == 0 then
					Interface:SetLocation("Ranks", 1)
					Interface.Popup:New({
						Type = "Notice",
						Text = `Rank '<font color="#ffbfaa">{self.Arguments.Rank.Name}</font>' successfuly removed.`,
						Time = 20,
					})
					
					self.Arguments.Busy = false
					return
				end
				
				local Error = "Unknown error occurred."
				if Response[1] == 1 then
					Error = `Rank higher than '<font color="#ffbfaa">{RChangeRanks.Name}</font>' required.`
				elseif Response[1] == 2 then
					Error = `Data that has been sent to server is invalid.`
				elseif Response[1] == 3 then
					Error = `Unable to remove rank rank with the owner permissions.`
				elseif Response[1] == 4 then
					Error = `Rank higher than '<font color="#ffbfaa">{self.Arguments.Rank.Name}</font>' required.`
				end
				
				Interface.Popup:New({
					Type = "Error",
					Text = Error,
					Time = 20,
				})
				
				self.Arguments.Busy = false
			end,
		})
	end)
	
	Page.AddPlayer.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.AddPlayer.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Busy then
			return
		end
		
		Page.List.Add.Visible = true
		Page.List.Add.Input.Input.Text = ""
	end)
	
	Page.List.Add.Cancel.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.List.Add.Cancel.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		Page.List.Add.Visible = false
	end)
	
	Page.List.Add.Confirm.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.List.Add.Confirm.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		local Input = Page.List.Add.Input.Input.Text
		
		if self.Arguments.Busy then
			return
		end
		
		self.Arguments.Busy = true
		if Input:gsub("%s+", "") == "" then
			Page.List.Add.Visible = false
			return
		end
		
		UIService:SetLoading(UI.MainFrame, function()
			return not self.Arguments.Busy or not Frame.Pages["1"].Visible
		end)
		
		local Success, Name = pcall(function()
			return Players:GetNameFromUserIdAsync(tonumber(Input))
		end)
		
		local UserId = Success and tonumber(Input) or Players:GetUserIdFromNameAsync(Input)
		if not UserId then
			Interface.Popup:New({
				Type = "Error",
				Text = `Unable to find player from input '{Input}'.`,
			})
			
			return
		end
		
		local Success, Name = pcall(function()
			return Players:GetNameFromUserIdAsync(UserId)
		end)
		
		local Success, Response = Remote:Fire("AddUser", self.Arguments.Rank.Rank, UserId)
		Page.List.Add.Visible = not Success
		self.Arguments.Busy = false
		
		if not Success then
			Interface.Popup:New({
				Type = "Error",
				Text = Response,
				Time = 20,
			})
			
			return
		end
		
		--self:RefreshUsers(UI, Frame, Interface)
		task.wait()
		
		self.Arguments.Rank = RankService:Find(self.Arguments.Rank.Rank)
		Interface.Popup:New({
			Type = "Notice",
			Text = `User '<font color="#ffbfaa">{Name}</font>' successfuly added.`
		})
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	Page.List.Add.Visible = false
	local RankData = RankService:Find(Arguments.Rank)
	Page.Error.Visible = RankData == nil
	
	if not RankData then
		warn(`[GAdmin Interface]: _Rank :: Rank '{Arguments.Rank}' is not valid.`)
		Page.Error.Scrollable.Error.Text = `Page hasn't been loaded.`
		return
	end
	
	local Success, Name = pcall(function()
		return RankData.ByAddon or Players:GetNameFromUserIdAsync(tonumber(RankData.MadeBy) or Cache.CreatorId)
	end)
	
	local MadeBy = Success and Name or "N/A"
	Page.MadeBy.Scrollable.MadeBy.Text = RankData.ByAddon and `Added By Addon: <font color="#5a00f5">{MadeBy}</font>` or `Last Modified By: {MadeBy}`
	local EditPermission = Cache.Session.Rank >= RChangeRanks.Rank and Cache.Session.Rank > RankData.Rank and RankData.Rank < 5 and not RankData.__Global
	
	Page.ChangeRank.Visible = EditPermission
	Page.RemoveRank.Visible = EditPermission
	Page.AddPlayer.Visible = EditPermission
	
	self.Arguments.Rank = RankData
	UI.MainFrame.Top.Title.Text = RankData.Name
	
	Page.Rank.Rank.Text = `Rank: {RankData.Rank}`
	Page.Players.Scrollable.Players.Text = `Users ({#RankData.Players})`
	
	if self.Arguments.Thread and coroutine.status(self.Arguments.Thread) == "running" then
		coroutine.close(self.Arguments.Thread)
	end
	
	self.Arguments.Thread = task.spawn(function()
		self:RefreshUsers(UI, Frame, Interface)
	end)
end

function Place:RefreshUsers(UI, Frame, Interface)
	if not self.Arguments.Rank then
		return
	end
	
	for i, Frame in ipairs(Frame.Pages["1"].List:GetChildren()) do
		if not Frame:IsA("TextButton") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Error = Frame.Pages["1"].Error
	Error.Visible = true
	Error.Scrollable.Error.Text = "Loading.."
	
	self.Arguments.Debounce = tick()
	if self.Arguments.Rank.__Global then
		Error.Scrollable.Error.Text = `This rank is global, which means almost everybody have it.`
		return
	end
	
	if RGlobalRanked.Rank > Cache.Session.Rank then
		Error.Scrollable.Error.Text = `Rank <font color="#ffbfaa">{RGlobalRanked.Name}+</font> required.`
		return
	end
	
	local Users = RankService:GetUsers(self.Arguments.Rank.Name)
	if not Users then
		Error.Scrollable.Error.Text = `Unable to get users with this rank.`
		return
	end
	
	Frame.Pages["1"].Players.Scrollable.Players.Text = `Users ({#Users})`
	if #Users <= 0 then
		Error.Scrollable.Error.Text = `No users were found with this rank.`
		return
	end
	
	Error.Visible = false
	local EditPermission = Cache.Session.Rank > RChangeRanks.Rank and self.Arguments.Rank.Rank < 5
	

	for i, PlayerLike in ipairs(Users) do
		local UserId = (type(PlayerLike) == "number" and PlayerLike or game.Players:GetUserIdFromNameAsync(PlayerLike)) or 1
		local Template = UIService:CreatePlayer(GuiAssets.RankPlayer, UserId, "%s")
		
		local Success, Name = pcall(function()
			return Players:GetNameFromUserIdAsync(UserId)
		end)
		
		Name = Success and Name or "N/A"
		Template.RemovePlayer.Visible = EditPermission
		
		Template.RemovePlayer.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			if self.Arguments.Busy then
				return
			end
			
			if self.Arguments.Confirmation and not self.Arguments.Confirmation.Destroyed then
				self.Arguments.Confirmation:Destroy()
			end
			
			self.Arguments.Busy = true
			self.Arguments.Confirmation = ConfirmationConstructor.new({
				Place = self.Name,
				Page = 1,

				Description = `Are you sure you want to unrank user '<font color="#ffbfaa">{Name}</font>'? This action can't be undone.`,
				Callback = function(Confirmation, Confirmed)
					if not Confirmed then
						self.Arguments.Busy = false
						return
					end
					
					UIService:SetLoading(UI.MainFrame, function()
						return not self.Arguments.Busy or not Frame.Pages["1"].Visible
					end)

					local Successs, Response = Remote:Fire("RemoveUser", UserId)
					if not Successs then
						Interface.Popup:New({
							Type = "Error",
							Text = Response,
							Time = 20,
						})
					end

					self.Arguments.Busy = false
					--self:RefreshUsers(UI, Frame, Interface)
					
					task.wait()
					self.Arguments.Rank = RankService:Find(self.Arguments.Rank.Rank)
					
					Interface.Popup:New({
						Type = "Notice",
						Text = `User '<font color="#ffbfaa">{Name}</font>' successfuly removed.`
					})
				end,
			})
		end)
		
		Template.LayoutOrder = i
		Template.Parent = Frame.Pages["1"].List
	end
end

return Place