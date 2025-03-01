--== << Services >>
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local StarterGui = game:GetService("StarterGui")
local Main = script:FindFirstAncestor("GAdminShared")

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local Sound = require(Main.Shared.Services.Sound)
local Remote = require(Main.Shared.Services.Remote)

local AutoFill = require(script.AutoFill)
local BackpackEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
--==

local CmdBar = {}
CmdBar.__index = CmdBar
CmdBar.__type = "GAdmin CmdBar"

function CmdBar:__tostring()
	return self.__type
end

function CmdBar:Run()
	local Success, Response = Remote:Fire("RunCommand", self.Input)
	local Data = {
		Content = self.Input,
		Success = Success,
		Timestamp = DateTime.now().UnixTimestamp
	}

	table.insert(self.History, Data)
	
	self.Request = {
		Data = Data,
		Success = Success,
		Response = Response,
	}
	
	self:Update()
end

function CmdBar:Update()
	self.Input = self.UI.MainFrame.CmdBar.InputFrame.Input.Text
	for i, Frame in ipairs(self.UI.MainFrame.CmdBar.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Recent = {}
	table.move(self.History, math.max(#self.History - 3, 1), #self.History, 1, Recent)
	
	for i, Cmd in ipairs(Recent) do
		local Frame = GuiAssets.Cmd:Clone()
		Frame.Name = i
		
		Frame.Content.Text = Cmd.Content
		Frame.Time.Text = DateTime.fromUnixTimestamp(Cmd.Timestamp):FormatLocalTime("HH:mm:ss", "en-us")
		
		Frame.State.Text = Cmd.Success and "SUCCESS" or "FAILURE"
		Frame.State.TextColor3 = Cmd.Success and Color3.new(0.356863, 0.6, 0.270588) or Color3.new(0.6, 0.266667, 0.266667)
		
		Frame.LayoutOrder = i
		Frame.Parent = self.UI.MainFrame.CmdBar.List
	end
	
	for i, Frame in ipairs(self.UI.MainFrame.CmdBar.AutoFill:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	self.AutoFill = self:GetAutoFill()
	self.Selected = 1
	
	for i, Fill in ipairs(self.AutoFill) do
		local Frame = GuiAssets.Fill:Clone()
		Frame.Name = i
		Frame.Content.Text = type(Fill) == "table" and (Fill.Display or Fill.ToFill) or Fill
		
		Frame.LayoutOrder = i
		Frame.Parent = self.UI.MainFrame.CmdBar.AutoFill
		
		Frame.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
			self.Selected = i
			self:UpdateSelected()
		end)
		
		Frame.Interact.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			self.Selected = i
			self:SelectFill()
		end)
	end
	
	self:UpdateSelected()
end

function CmdBar:UpdateSelected()
	for i, Fill in ipairs(self.AutoFill) do
		local Frame = self.UI.MainFrame.CmdBar.AutoFill:FindFirstChild(tostring(i))
		if not Frame then
			continue
		end
		
		local IsSelected = i == self.Selected
		Frame.BackgroundColor3 = IsSelected and Color3.new(0.117647, 0.207843, 0.462745) or Color3.new(0.0823529, 0.145098, 0.329412)
	end
end

function CmdBar:SelectFill(Selected)
	Selected = Selected or self.Selected
	local Fill = self.AutoFill[Selected]
	
	if not Fill then
		return
	end
	
	Fill = type(Fill) == "table" and Fill.ToFill or Fill
 	local String, Cursor = AutoFill:Fill(self.Input, self.Cursor, Fill)
	self.UI.MainFrame.CmdBar.InputFrame.Input.Text = String
	self.UI.MainFrame.CmdBar.InputFrame.Input.CursorPosition = Cursor
end

function CmdBar:GetAutoFill(Input)
	local Cursor = self.UI.MainFrame.CmdBar.InputFrame.Input.CursorPosition
	Input = Input or self.Input
	
	Input = Input:sub(1, Cursor)
	return AutoFill:Get(Input)
end

function CmdBar:Clear()
	self.History = {}
	self.UI.MainFrame.CmdBar.InputFrame.Input.Text = ""
	self:Update()
end

function CmdBar:ChangeState(State)
	if State == nil then
		State = not self.Opened
	end
	
	if State then
		self:Open()
		return
	end
	
	self:Close()
end

function CmdBar:Open()
	if self.Opened then
		return
	end
	
	self.UI.MainFrame.CmdBar.InputFrame.Input.Text = ""
	self.Opened = true
	if self.__Tween then self.__Tween:Pause() end
	
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, BackpackEnabled)
	end)
	
	self.__Tween = TweenService:Create(self.UI.MainFrame, self.TweenInfo, {Position = UDim2.fromScale(0, 0)})
	self.__Tween:Play()
end

function CmdBar:Close()
	if not self.Opened then
		return
	end
	
	self.Opened = false
	if self.__Tween then self.__Tween:Pause() end
	
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)
	
	self.__Tween = TweenService:Create(self.UI.MainFrame, self.TweenInfo, {Position = UDim2.fromScale(0, -1)})
	self.__Tween:Play()
end

function CmdBar:Destroy()
	for i, Connection in ipairs(self.__Connections) do
		Connection:Disconnect()
	end
	
	setmetatable(self, nil)
	table.clear(self)
end

return {
	new = function(Gui)
		local NewBar = setmetatable({}, CmdBar)
		NewBar.__Connections = {}
		
		NewBar.Opened = false
		NewBar.Focused = false
		
		NewBar.History = {}
		NewBar.Cursor = 1
		
		NewBar.UI = Gui
		NewBar.Input = ""
		
		NewBar.Key = Enum.KeyCode.Semicolon
		NewBar.Request = {}
		
		NewBar.Selected = 1
		NewBar.AutoFill = {}
		
		NewBar.TweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Sine)
		table.insert(NewBar.__Connections, NewBar.UI.MainFrame.CmdBar.InputFrame.Input:GetPropertyChangedSignal("CursorPosition"):Connect(function()
			local Cursor = NewBar.UI.MainFrame.CmdBar.InputFrame.Input.CursorPosition
			if Cursor < 0 then
				return
			end
			
			NewBar.Cursor = Cursor
		end))
		
		table.insert(NewBar.__Connections, NewBar.UI.MainFrame.CmdBar.InputFrame.Input:GetPropertyChangedSignal("Text"):Connect(function()
			NewBar:Update()
		end))
		
		table.insert(NewBar.__Connections, NewBar.UI.MainFrame.CmdBar.InputFrame.Input.Focused:Connect(function()
			NewBar.Focused = true
		end))
		
		table.insert(NewBar.__Connections, NewBar.UI.MainFrame.CmdBar.InputFrame.Input.FocusLost:Connect(function(EnterPressed)
			NewBar.Focused = false
			if not EnterPressed or NewBar.Input:gsub("%s+", "") == "" then
				return
			end

			NewBar:Run()
			NewBar.UI.MainFrame.CmdBar.InputFrame.Input.Text = ""
			NewBar.UI.MainFrame.CmdBar.InputFrame.Input:CaptureFocus()
		end))

		table.insert(NewBar.__Connections, UserInputService.InputBegan:Connect(function(InputKey, GameProcessedEvent)
			if InputKey.KeyCode == Enum.KeyCode.Up and NewBar.Opened then
				local Next = NewBar.Selected - 1
				Next = if Next <= 0 then #NewBar.AutoFill else (if Next > #NewBar.AutoFill then 1 else Next)
				
				NewBar.Selected = Next
				NewBar:UpdateSelected()
			end
			
			if InputKey.KeyCode == Enum.KeyCode.Down and NewBar.Opened then
				local Next = NewBar.Selected + 1
				Next = if Next <= 0 then #NewBar.AutoFill else (if Next > #NewBar.AutoFill then 1 else Next)
				
				NewBar.Selected = Next
				NewBar:UpdateSelected()
			end
			
			if InputKey.KeyCode == Enum.KeyCode.Tab and #NewBar.AutoFill > 0 and NewBar.Focused then
				local Input = NewBar.UI.MainFrame.CmdBar.InputFrame.Input
				NewBar:SelectFill()
				Input:CaptureFocus()
				
				task.wait()
				Input.Text = Input.Text:sub(1, #Input.Text - 1)
			end
			
			if (InputKey.KeyCode == NewBar.Key or InputKey.UserInputType == NewBar.Key) and not NewBar.Focused and not GameProcessedEvent then
				NewBar:ChangeState()
			end
		end))
		
		return NewBar
	end,
}