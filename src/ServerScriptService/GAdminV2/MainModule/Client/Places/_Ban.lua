--== << Services >>
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Time = require(Main.Shared.Services.Core.Time)
local Popup = require(Main.Shared.Services.Popup)

local Remote = require(Main.Shared.Services.Remote)
local Inputs = require(Main.Client.Services.Framework.Settings.Inputs)

local ConfirmationConstructor = require(Main.Client.Services.Framework.Confirmation)
local UIService = require(Main.Client.Services.UI)
--==

local Place = {}
Place.Name = "_Ban"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Banning = false,
	User = nil,
	
	UserRaw = "",
	Reason = "",

	Time = nil,
	TimeRaw = "",

	DetectAlts = false,
	Request = {},
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	self.Request = {
		Object = Page.Arguments.List.API.InputFrame.Boolean,
		Connections = self:GetRequest(Page, Interface),
	}

	Page.Arguments.List.User.InputFrame.Input.FocusLost:Connect(function()
		local Input = Page.Arguments.List.User.InputFrame.Input.Text
		self.Arguments.UserRaw = Input
		self:UpdateUser(Page, Interface)
	end)

	Page.Arguments.List.Time.InputFrame.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local Input = Page.Arguments.List.Time.InputFrame.Input.Text
		self.Arguments.TimeRaw = Input
		self:UpdateTime(Page, Interface)
	end)

	Page.Arguments.List.Reason.InputFrame.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local Input = Page.Arguments.List.Reason.InputFrame.Input.Text
		self.Arguments.Reason = Input
	end)

	Page.Submit.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Page.Submit.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.Banning then
			return
		end
		
		local Success, Response = self:IsValid()
		if not Success then
			Popup:New({
				Type = "Error",
				Text = Response
			})

			return
		end
		
		self.Arguments.Banning = true
		Page.Submit.Interactable = false
		Page.Arguments.Interactable = false
		
		local Confirmation = ConfirmationConstructor.new({
			Place = self.Name,
			Page = 1,

			Description = `Are you sure you want to ban player <font color="#ffbfaa">{self.Arguments.User.Name}</font>?`,
			Callback = function(Confirmation, Confirmed)
				Page.Submit.Interactable = true
				Page.Arguments.Interactable = true
				
				if not Confirmed then
					self.Arguments.Banning = false
					return
				end

				UIService:SetLoading(UI.MainFrame, function()
					return not self.Arguments.Banning or not Page.Visible
				end)
				
				local Options = {
					Time = self.Arguments.Time,
					Locally = self.Arguments.Type == "Server",
					
					Reason = self.Arguments.Reason,
					API = self.Arguments.DetectAlts,
					ApplyToUniverse = self.Arguments.DetectAlts,
				}

				local Success, Response = Remote:Fire("Ban", self.Arguments.User.UserId, Options)
				self.Arguments.Banning = false

				if not Success then
					Interface.Popup:New({
						Type = "Error",
						Text = Response or "An unexpected error occurred. Please, try again later.",
						Time = 20,
					})

					return
				end

				Interface:SetLocation(Interface.Location.Place, Interface.Location.Page)
				Interface.Popup:New({
					Type = "Notice",
					Text = `User <font color="#ffbfaa">{self.Arguments.User.Name}</font> is successfuly banned.`,
					Time = 20,
				})
			end,
		})
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Type = Arguments.Type or "Global"
	UI.MainFrame.Top.Title.Text = `{self.Arguments.Type} Ban`
	self:Clear(Page, Interface)
end

function Place:SetAlts(State)
	if State == nil then
		State = not self.DetectAlts
	end

	Inputs.Boolean.Set(self.Request, State)
end

function Place:Clear(Page, Interface)
	Page.Arguments.List.User.InputFrame.Input.Text = ""
	Page.Arguments.List.Time.InputFrame.Input.Text = ""
	Page.Arguments.List.Reason.InputFrame.Input.Text = ""
	
	self.Arguments.User = nil
	self.Arguments.Time = nil
	
	self.Arguments.Reason = ""
	self.Arguments.UserRaw = ""
	self.Arguments.TimeRaw = ""

	self:SetAlts(false)
	self:UpdateUser(Page, Interface)
end

function Place:IsValid()
	if not self.Arguments.User then
		return false, `Provided <font color="#ffbfaa">User</font> does not exist.`
	end
	
	if not self.Arguments.Time then
		return false, `Provided <font color="#ffbfaa">Time</font> structure is not valid.`
	end
	
	return true
end

function Place:UpdateUser(Page, Interface)
	local Frame = Page.User
	local UserLike = self.Arguments.UserRaw

	if UserLike:gsub("%s+", "") == "" then
		Frame.Avatar.Error.Visible = true
		Frame.Avatar.Image = ""

		Frame.UserId.UserId.Text = `UserId: N/A`
		Frame.Username.Username.Text = `N/A`
		self.Arguments.User = nil
		return
	end

	local UserId = tonumber(UserLike)
	local IsName = not UserId

	if not UserId then
		local Success, Response = pcall(function()
			return Players:GetUserIdFromNameAsync(UserLike)
		end)

		UserId = Success and Response or "N/A"
	end

	local Name = IsName and UserLike or nil
	if not IsName then
		local Success, Response = pcall(function()
			return Players:GetNameFromUserIdAsync(UserLike)
		end)

		Name = Success and Response or "N/A"
	end

	local ImageSuccess, Image = pcall(function()
		return Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	Frame.Avatar.Error.Visible = not ImageSuccess
	Frame.Avatar.Image = ImageSuccess and Image or ""

	Frame.UserId.UserId.Text = `UserId: {UserId}`
	Frame.Username.Username.Text = Name
	
	self.Arguments.User = {
		UserId = UserId,
		Name = Name
	}
end

function Place:UpdateTime()
	local TimeLike = self.Arguments.TimeRaw
	if TimeLike:gsub("%s+", "") == "" then
		self.Arguments.Time = nil
		return
	end
	
	local Success, Seconds = Time:GetSeconds(TimeLike, " ")
	if not Success then
		self.Arguments.Time = nil
		return
	end
	
	self.Arguments.Time = Seconds
end

function Place:GetRequest(Page, Interface)
	local Object = Page.Arguments.List.API.InputFrame.Boolean
	local Connections = {}
	local Info = TweenInfo.new(.2, Enum.EasingStyle.Sine)

	Connections.Tween1 = TweenService:Create(Object.Slider, Info, {Position = UDim2.fromScale(0, 0), AnchorPoint = Vector2.new(0, 0)})
	Connections.Tween2 = TweenService:Create(Object.Slider, Info, {Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0)})

	table.insert(Connections, Object.Input.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		local State = not Object.Input:GetAttribute("State")

		Object.Input:SetAttribute("State", State)
		Object.State.Text = State and "Enabled" or "Disabled"
		self.Arguments.DetectAlts = State

		Connections.Tween1:Pause()
		Connections.Tween2:Pause()

		if State then
			Connections.Tween1:Play()
			return
		end

		Connections.Tween2:Play()
	end))

	return Connections
end

return Place