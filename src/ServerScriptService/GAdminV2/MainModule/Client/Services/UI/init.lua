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

UI.Popups = 0
UI.Gui = Gui

UI.__Loadings = {}
UI.Whitelist = {"CanvasGroup", "TextLabel", "TextButton", "ImageButton", "ImageLabel", "Frame", "ScrollingFrame", "TextBox", "VideoFrame", "ViewportFrame"}

UI.__ThemeMemory = nil
UI.__ThemeActive = false
UI.__ThemeConnections = {}

UI.Theme = {
	Hue = nil,
	Saturation = nil,
	Value = nil
}

repeat
	task.wait()
until _G.GAdmin

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

function UI:__SetTheme(Object)
	if Object:GetAttribute("GA_ConstantTheme") then
		return
	end
	
	self.__ThemeMemory[Object] = self.__ThemeMemory[Object] or Object.BackgroundColor3
	Object.BackgroundColor3 = self:GetTheme(self.__ThemeMemory[Object])
end

function UI:RefreshTheme()
	self.__ThemeActive = true
	self:SetTheme(self.Theme.Hue, self.Theme.Saturation, self.Theme.Value)
end

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
	
	for i, Connection in ipairs(self.__ThemeConnections) do
		Connection:Disconnect()
	end
	
	table.insert(self.__ThemeConnections, self.Gui.DescendantAdded:Connect(function(Object)
		if not Object:IsA("GuiObject") then
			return
		end
		
		self:__SetTheme(Object)
		
		--pcall(function()
		--	self.__ThemeMemory[Object] = Object.BackgroundColor3
		--	self:__SetTheme(Object)
		--end)
	end))
	
	table.insert(self.__ThemeConnections, self.Gui.DescendantRemoving:Connect(function(Object)
		if not self.__ThemeMemory[Object] then
			return
		end

		self.__ThemeMemory[Object] = nil
	end))
	
	for i, Object in ipairs(self.Gui:GetDescendants()) do
		if not Object:IsA("GuiObject") then
			continue
		end
		
		self:__SetTheme(Object)
		
		--pcall(function()
		--	self.__ThemeMemory[Object] = self.__ThemeMemory[Object] or Object.BackgroundColor3
		--	self:__SetTheme(Object)
		--end)
	end
	
	--print(self.__ThemeMemory)
end

function UI:ClearTheme()
	if not self.__ThemeActive then
		return
	end
	
	for i, Connection in ipairs(self.__ThemeConnections) do
		Connection:Disconnect()
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

function UI:IsLoading(Frame)
	local Index, Loading = self:GetLoading(Frame)
	return Index ~= nil
end

function UI:GetLoading(Frame)
	for i, Loading in ipairs(self.__Loadings) do
		if Loading.Frame ~= Frame then
			continue
		end

		return i, Loading
	end
end

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