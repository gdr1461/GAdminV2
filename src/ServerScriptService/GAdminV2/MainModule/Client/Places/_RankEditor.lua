--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local ColorPicker = require(Main.Client.Services.ColorPicker)
local Cache = require(Main.Client.Services.Framework.Cache)
local RankService = require(Main.Shared.Services.Rank)

local UIService = require(Main.Client.Services.UI)
local Remote = require(Main.Shared.Services.Remote)

local Restrictions = require(Main.Settings.Restrictions)
local RChangeRanks = RankService:Find(Restrictions.Ranks.ChangeRanks)
--==

local Place = {}
Place.Name = "_RankEditor"
Place.Previous = {
	Place = "Ranks",
	Page = 1
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Busy = false,
	Pallete = ColorPicker.new(false),
	DefaultColor = nil,
	
	Name = nil,
	Rank = nil,
	
	Color = nil,
	Players = {},
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	Page.RankName.Input.FocusLost:Connect(function()
		Page.RankName.Input.PlaceholderText = "Name"
		self.Arguments.Name = Page.RankName.Input.Text
	end)
	
	Page.Rank.Input.FocusLost:Connect(function()
		Page.Rank.Input.PlaceholderText = "Rank"
		self.Arguments.Rank = tonumber(Page.Rank.Input.Text, 10)
	end)
	
	Page.Add.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	self.Arguments.DefaultColor = Page.Color.BackgroundColor3
	self.Arguments.Pallete:SetColor(self.Arguments.DefaultColor)
	self.Arguments.Color = self.Arguments.DefaultColor
	
	Interface:SetHoverConfig(self.Arguments.Pallete.frame, function(Object)
		local RawPosition = Page.Color.AbsolutePosition
		return UDim2.fromOffset(RawPosition.X, RawPosition.Y)
	end)
	
	Page.Color.Activated:Connect(function()
		if self.Arguments.Pallete.active then
			return
		end
		
		local Object = self.Arguments.Pallete.frame
		local RawPosition = Page.Color.AbsolutePosition
		local Position = UDim2.fromOffset(RawPosition.X, RawPosition.Y)
		
		local AdjustedPosition = Interface:GetFixedPosition(Object, Position)
		Object.Position = AdjustedPosition
		self.Arguments.Pallete:Start()
	end)
	
	Interface:OnLocationChange(function(Location)
		if Location.Place == self.Name then
			return
		end
		
		self.Arguments.Pallete:Cancel()
	end)
	
	self.Arguments.Pallete.Changed:Connect(function(Color)
		Page.Color.BackgroundColor3 = Color
		self.Arguments.Color = Color
	end)
	
	Interface:SetHover(Page.Rank, "Rank is a number between 1-4, can be a decimal.")
	Interface:SetHover(Page.Color, "Color of the rank.")
	
	Page.Add.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.Busy then
			return
		end
		
		self:SetUsers(Page)
		self.Arguments.Busy = true
		
		Frame.Interactable = false
		UIService:SetLoading(UI.MainFrame, function()
			return not self.Arguments.Busy or not Page.Visible
		end, {
			OnEnd = function()
				Frame.Interactable = true
			end,
		})
		
		local Success = self:Apply(UI, Frame, Interface)
		self.Arguments.Busy = false
		
		if Success ~= false then
			return
		end
		
		Sound:Play("Notification", "Error")
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	local RankData = Arguments.Rank or {
		Name = "",
		Rank = "",
		Players = {},
		Color = self.Arguments.DefaultColor
	}
	
	UI.MainFrame.Top.Title.Text = "Rank Editor"
	Page.RankName.Input.Text = RankData.Name
	Page.Rank.Input.Text = RankData.Rank
	Page.Players.Input.Text = #RankData.Players > 0 and table.concat(RankData.Players, ", ") or ""
	
	self.Arguments.Name = RankData.Name:gsub("%s+", "") ~= "" and RankData.Name or nil
	self.Arguments.Rank = tostring(RankData.Rank):gsub("%s+", "") ~= "" and tonumber(RankData.Rank) or nil
	self.Arguments.Players = RankData.Players

	self.Arguments.Action = Arguments.Action or "Add"
	self.Arguments.Tag = RankData.Name
	
	local Color = type(RankData.Color) == "string" and Color3.fromHex(RankData.Color) or RankData.Color
	self.Arguments.Pallete:SetColor(Color)
	self.Arguments.Color = Color
end

function Place:SetUsers(Page)
	Page.Players.Input.PlaceholderText = "Users"
	local UserData = Page.Players.Input.Text:gsub("%s+", ""):split(",")
	
	self.Arguments.Players = {}
	for i, UserLike in ipairs(UserData) do
		if UserLike:gsub("%s+", "") == "" then
			return
		end

		local UserId = tonumber(UserLike, 10) or game.Players:GetUserIdFromNameAsync(UserLike)
		if not UserId then
			Page.Players.Input.PlaceholderText = `User '{UserId}' is invalid.`
			Page.Players.Input.Text = ""

			self.Arguments.Players = nil
			return
		end

		table.insert(self.Arguments.Players, UserId)
	end
end

function Place:Apply(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	local Name = self.Arguments.Name
	
	local Rank = self.Arguments.Rank
	local Color = self.Arguments.Color
	local Players = self.Arguments.Players
	
	if not Name then
		Page.RankName.Input.PlaceholderText = "Name is required field."
		Page.RankName.Input.Text = ""
		return false
	end
	
	local RankData = {
		Name = Name,
		Rank = Rank,
		Players = Players,
		Color = Color:ToHex(),
	}
	
	local ToChange = self.Arguments.Action == "Change"
	local NameData = RankService:Find(Name)
	local DataRank = RankService:Find(Rank)
	
	if (NameData and not ToChange) then
		Page.RankName.Input.PlaceholderText = "Name needs to be unique."
		Page.RankName.Input.Text = ""
		return false
	end
	
	if (DataRank and not ToChange) then
		Interface.Popup:New({
			Type = "Error",
			Text = "Rank needs to be unique.",
			Time = 20,
		})

		Page.Rank.Input.Text = ""
		return
	end
	
	if not Rank then
		Interface.Popup:New({
			Type = "Error",
			Text = "Rank is required field.",
			Time = 20,
		})
		
		Page.Rank.Input.Text = ""
		return
	end
	
	if Rank >= 5 or Rank <= 0 then
		Interface.Popup:New({
			Type = "Error",
			Text = "Rank can go 1-4 only.",
			Time = 20,
		})
		
		Page.Rank.Input.Text = ""
		return
	end
	
	if Rank > Cache.Session.Rank then
		Interface.Popup:New({
			Type = "Error",
			Text = "Rank needs to be lower than yours.",
			Time = 20,
		})
		
		Page.Rank.Input.Text = ""
		return
	end
	
	if not self.Arguments.Players then
		return false
	end
	
	local Response = Remote:Fire("SetRank", self.Arguments.Action, {
		Name = Name,
		Rank = Rank,
		Color = Color,
		Players = Players,
		Tag = self.Arguments.Tag
	}, false)
	
	if Response[1] == 0 then
		Interface:SetLocation("Ranks", 1)
		Interface.Popup:New({
			Type = "Notice",
			Text = `Rank '<font color="#ffbfaa">{Name}</font>' successfuly edited.`,
			Time = 20,
		})

		return
	end

	local Error = "Unknown error occurred."
	if Response[1] == 1 then
		Error = `Rank higher than '<font color="#ffbfaa">{RChangeRanks.Name}</font>' required.`
	elseif Response[1] == 2 then
		Error = `Data that has been sent to server is invalid.`
	elseif Response[1] == 3 then
		Error = `Unable to set rank higher than rank with owner permissions.`
	elseif Response[1] == 4 then
		Error = `Rank higher than '<font color="#ffbfaa">{Response[2].Name}</font>' required.`
	elseif Response[1] == 5 then
		Error = `User '{Response[2]}' is invalid.`
	elseif Response[1] == 6 then
		local UserName = tonumber(Response[2][1], 10) and game.Players:GetNameFromUserIdAsync(Response[2][1]) or Response[2][1]
		local UserRank = RankService:Find(Response[2][2])
		Error = `Rank of <font color="#ffbfaa">{UserName}</font> is higher than yours. (<font color="#ffbfaa">{UserRank.Name}</font>)`
	end

	Interface.Popup:New({
		Type = "Error",
		Text = Error,
		Time = 20,
	})
end

return Place