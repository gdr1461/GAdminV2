--[=[
	@class UI
	@client
	@tag UI
	UI Utils for GAdmin.

	Location: `GAdminV2.MainModule.Client.Services.UI`
]=]

--[=[
	@interface UI
	@field __type string
	@field Popups number
	@field Gui ScreenGui
	@field __Loadings {LoadingTable}
	@field Whitelist {string}
	@field __ThemeMemory {[GuiObject]: Color3}
	@field __ThemeActive boolean
	@field __ThemeConnections {RBXScriptConnection}
	@field Theme Theme
	@field RenderStepped RBXScriptConnection
	@field __CheckLoadings () -> nil
	@field __SetTheme (Object: GuiObject) -> nil
	@field RefreshTheme () -> nil
	@field GetTheme (Color: Color3) -> Color3
	@field SetTheme (Hue: number, Saturation: number, Value: number) -> nil
	@field ClearTheme () -> nil
	@field IsLoading (Frame: Frame) -> boolean
	@field GetLoading (Frame: Frame) -> number, LoadingTable
	@field CreatePlayer (Template: Frame, UserId: number, Format: string) -> Frame
	@field SetLoading (Frame: Frame, Check: () -> boolean, Options: table) -> nil
	@field BreakLoading (Frame: Frame) -> nil
	@within UI
]=]

--[=[
	@interface LoadingTable
	@field Frame Frame -- The frame to load.
	@field Loading Frame -- The loading frame.
	@field Tween Tween -- The tween of the loading.
	@field Check () -> boolean -- The check to run.
	@within UI
]=]

--[=[
	@interface Theme
	@field Hue number
	@field Saturation number
	@field Value number
	@within UI
]=]

--== << Services >>
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Main = script:FindFirstAncestor("GAdminShared")
local Sound = require(Main.Shared.Services.Sound)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local PlayerGui = player.PlayerGui
local Gui = PlayerGui:WaitForChild("GAdmin")
--==

local Proxy = newproxy(true)
local UI = getmetatable(Proxy)

UI.__type = "GAdmin UI"
UI.__metatable = "[GAdmin UI]: Metatable methods are restricted."

--[=[
	Amount of popups user got.

	@prop Popups number
	@within UI
]=]
UI.Popups = 0

--[=[
	Main ScreenGui of the panel.

	@prop Gui ScreenGui
	@within UI
]=]
UI.Gui = Gui

--[=[
	Current loading frames in the UI.

	@prop __Loadings {LoadingTable}
	@private
	@within UI
]=]
UI.__Loadings = {}

--[=[
	Whitelist of UI objects to theme.

	@prop Whitelist {string}
	@within UI
]=]
UI.Whitelist = {"CanvasGroup", "TextLabel", "TextButton", "ImageButton", "ImageLabel", "Frame", "ScrollingFrame", "TextBox", "VideoFrame", "ViewportFrame"}

--[=[
	GuiObject colors before theme.

	@prop __ThemeMemory {[GuiObject]: Color3}
	@private
	@within UI
]=]
UI.__ThemeMemory = {}

--[=[
	If the theme is active.

	@prop __ThemeActive boolean
	@private
	@within UI
]=]
UI.__ThemeActive = false

--[=[
	Theme connections of the UI.

	@prop __ThemeObjects {[GuiObject]: {RBXScriptConnection}}
	@private
	@within UI
]=]
UI.__ThemeObjects = {}

--[=[
	Current theme of the UI.

	@prop Theme Theme
	@within UI
]=]
UI.Theme = {
	Hue = nil,
	Saturation = nil,
	Value = nil
}

repeat
	task.wait()
until _G.GAdmin

--[=[
	@prop RenderStepped RBXScriptConnection
	@private
	@within UI
]=]
UI.RenderStepped = _G.GAdmin.Render(function()
	UI:__CheckLoadings()
end)

function UI:__tostring()
	return self.__type
end

function UI:__index(Key)
	return UI[Key]
end

function UI:__newindex(Key, Value)
	UI[Key] = Value
end

--[=[
	Check loadings and remove completed ones.

	@private
	@within UI
	@return nil
]=]
function UI:__CheckLoadings()
	local Theme = self:GetTheme(Color3.new(0.12549, 0.156863, 0.25098))
	local SequencePoints = {
		ColorSequenceKeypoint.new(0, Theme),
		ColorSequenceKeypoint.new(.3, Theme),
		ColorSequenceKeypoint.new(.5, Color3.new(0.788235, 0.835294, 1)),
		ColorSequenceKeypoint.new(.7, Theme),
		ColorSequenceKeypoint.new(1, Theme),
	}
	
	local Sequence = ColorSequence.new(SequencePoints)
	for i, Data in ipairs(self.__Loadings) do
		if Data.Loading.UIGradient.Color ~= Sequence then
			Data.Loading.UIGradient.Color = Sequence
		end
		
		local Enabled = not Data.Check()
		Data.Frame.Interactable = not Enabled
	
		if Enabled then
			continue
		end

		self:BreakLoading(Data.Frame)
	end
end

--[=[
	Set theme of the UI Object.

	@param Object GuiObject -- The object to set theme of.
	@private
	@within UI
	@return nil
]=]
function UI:__SetTheme(Object)
	if Object:GetAttribute("GA_ConstantTheme") then
		return
	end
	
	self.__ThemeMemory[Object] = self.__ThemeMemory[Object] or Object.BackgroundColor3
	Object.BackgroundColor3 = self:GetTheme(self.__ThemeMemory[Object])
end

--[=[
	Refresh theme of the UI.

	@within UI
	@return nil
]=]
function UI:RefreshTheme()
	self.__ThemeActive = true
	self:SetTheme(self.Theme.Hue, self.Theme.Saturation, self.Theme.Value)
end

--[=[
	Get theme of the UI.

	@param Color Color3 -- The color to get theme of.
	@within UI
	@return Color3
]=]
function UI:GetTheme(Color)
	if not Color then
		local Hue = self.Theme.Hue
		local Saturation = self.Theme.Saturation
		local Value = self.Theme.Value
		
		return Color3.fromHSV(Hue, Saturation, Value)
	end
	
	local BHue, BSaturation, BValue = Color:ToHSV()
	
	--local HueDiff = self.Theme.Hue and math.max(self.Theme.Hue - BHue, 0) or BHue
	--local SatDiff = self.Theme.Saturation and math.max(self.Theme.Saturation - BSaturation, 0) or BSaturation
	--local ValDiff = self.Theme.Value and math.max(self.Theme.Value - BValue, 0) or BValue
	
	local Hue = self.Theme.Hue or BHue
	local Saturation = self.Theme.Saturation or BSaturation

	local Value = self.Theme.Value or BValue
	return Color3.fromHSV(Hue, Saturation, Value)
end

--[=[
	Set theme of the UIs.

	@param Hue number -- The hue of the theme.
	@param Saturation number -- The saturation of the theme.
	@param Value number -- The value of the theme.
	@within UI
	@return nil
]=]
function UI:SetTheme(Hue, Saturation, Value)
	--Hue = Hue and Hue + 1 or nil
	--Saturation = Saturation and math.min(Saturation, 1.8) or nil
	--Value = Value and math.min(Value, 1.8) or nil
	
	self.__ThemeActive = true
	self.Theme = {
		Hue = Hue,
		Saturation = Saturation,
		Value = Value,
	}
	
	if not self.__ThemeMemory then
		self.__ThemeMemory = {}
	end
	
	for Gui, Connections in pairs(self.__ThemeObjects) do
		for i, Object in ipairs(Gui:GetDescendants()) do
			if not Object:IsA("GuiObject") then
				continue
			end

			self:__SetTheme(Object)

			--pcall(function()
			--	self.__ThemeMemory[Object] = self.__ThemeMemory[Object] or Object.BackgroundColor3
			--	self:__SetTheme(Object)
			--end)
		end
	end
	
	--print(self.__ThemeMemory)
end

--[=[
	Clear theme of the UI.

	@within UI
	@return nil
]=]
function UI:ClearTheme()
	if not self.__ThemeActive then
		return
	end
	
	self.__ThemeActive = false
	for Object, Color in pairs(self.__ThemeMemory) do
		if not Object or not Object.Parent then
			self.__ThemeMemory[Object] = nil
			continue
		end
		
		pcall(function()
			Object.BackgroundColor3 = Color
		end)
	end
end

--[=[
	Bind object to theme change.

	@param GuiObject GuiObject -- The object to bind to the theme.
	@within UI
	@return nil
]=]
function UI:BindObjectToTheme(GuiObject)
	if self.__ThemeObjects[GuiObject] then
		return
	end
	
	self.__ThemeObjects[GuiObject] = {}
	for i, Object in ipairs(GuiObject:GetDescendants()) do
		if not Object:IsA("GuiObject") then
			continue
		end

		self:__SetTheme(Object)
	end

	table.insert(self.__ThemeObjects[GuiObject], self.Gui.DescendantAdded:Connect(function(Object)
		if not Object:IsA("GuiObject") or not self.__ThemeActive then
			return
		end

		self:__SetTheme(Object)
	end))

	table.insert(self.__ThemeObjects[GuiObject], self.Gui.DescendantRemoving:Connect(function(Object)
		if not self.__ThemeMemory[Object] or not self.__ThemeActive then
			return
		end

		self.__ThemeMemory[Object] = nil
	end))
end

--[=[
	Unbind object from theme change.

	@param GuiObject GuiObject -- The object to unbind from the theme.
	@within UI
	@return nil
]=]
function UI:UnBindObjectFromTheme(GuiObject)
	if not self.__ThemeObjects[GuiObject] then
		return
	end
	
	for i, Connection in ipairs(self.__ThemeObjects[GuiObject]) do
		Connection:Disconnect()
	end
	
	self.__ThemeObjects[GuiObject] = nil
end

--[=[
	Check if the frame is loading.

	@param Frame Frame -- The frame to check.
	@within UI
	@return boolean
]=]
function UI:IsLoading(Frame)
	local Index, Loading = self:GetLoading(Frame)
	return Index ~= nil
end

--[=[
	Get loading of the frame.

	@param Frame Frame -- The frame to get loading of.
	@within UI
	@return number, LoadingTable
]=]
function UI:GetLoading(Frame)
	for i, Loading in ipairs(self.__Loadings) do
		if Loading.Frame ~= Frame then
			continue
		end

		return i, Loading
	end
end

--[=[
	Create a new player frame from template.
	@param Template Frame -- The template to create the player frame from.
	@param UserId number -- The user id of the player.
	@param Format string -- The format of the username.

	@within UI
	@return Frame
]=]
function UI:CreatePlayer(Template, UserId, Format)
	Format = Format or "%s"
	local Success, Headshot = pcall(function()
		return game.Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	local Success, Name = pcall(function()
		return  game.Players:GetNameFromUserIdAsync(UserId)
	end)
	
	Name = Success and Name or "Player"
	Template = Template:Clone()

	Template.Name = `{Name}-{UserId}`
	Template.Scrollable.Username.Text = Format:format(Name)

	Template.Avatar.Error.Visible = not Success
	Template.Avatar.Image = Success and Headshot or ""
	
	Template.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	local IsName = true
	Template.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		IsName = not IsName
		Template.Scrollable.Username.Text = IsName and Format:format(Name) or Format:format(`UserId: {UserId}`)
	end)
	
	return Template
end

--[=[
	Set loading of the frame.

	@param Frame Frame -- The frame to set loading of.
	@param Check () -> boolean -- The check to run. If `true`, will remove the loading.
	@param Options table -- The options to set.
	@within UI
	@return nil
]=]
function UI:SetLoading(Frame, Check, Options)
	if self:IsLoading(Frame) then
		warn(`[{self.__type}]: Frame '{Frame}' is already loading.`)
		return
	end
	
	Options = Options or {}
	Options.Couplets = Options.Couplets or 2
	Options.Period = Options.Period or 2.5
	
	local Loading = GuiAssets.Loading:Clone()
	Loading.Parent = Frame
	Loading.Visible = true
	
	Loading.UIGradient.Offset = Vector2.new(-1, 0)
	local Tween = TweenService:Create(Loading.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
		Offset = Vector2.new(1, 0)
	})
	
	Tween:Play()
	local Total = 0

	Tween.Completed:Connect(function()
		Loading.UIGradient.Offset = Vector2.new(-1, 0)
		Total += 1
		
		if Total % Options.Couplets == 0 then
			task.wait(Options.Period)
		end
		
		Tween:Play()
	end)
	
	Tween.Destroying:Once(function()
		if not Options.OnEnd then
			return
		end
		
		Options.OnEnd()
	end)
	
	table.insert(self.__Loadings, {
		Frame = Frame,
		Loading = Loading,
		Tween = Tween,
		Check = Check
	})
end

--[=[
	Break loading of the frame.

	@param Frame Frame -- The frame to break loading of.
	@within UI
	@return nil
]=]
function UI:BreakLoading(Frame)
	local Index, Loading = self:GetLoading(Frame)
	if not Index then
		warn(`[{self.__type}]: Frame '{Frame}' is not loading.`)
		return
	end
	
	Loading.Tween:Destroy()
	Loading.Loading:Destroy()
	table.remove(self.__Loadings, Index)
end

return Proxy