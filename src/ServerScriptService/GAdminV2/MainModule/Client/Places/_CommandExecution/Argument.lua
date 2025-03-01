--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")

local AutoFill = require(Main.Client.Services.Framework.CmdBar.AutoFill)
local Sound = require(Main.Shared.Services.Sound)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
--==

local Argument = {}
Argument.Frame = nil
Argument.Connections = {}

Argument.Opened = false
Argument.Focused = false

Argument.Cursor = 1
Argument.Input = ""

Argument.Selected = 1
Argument.AutoFill = {}

function Argument:Refresh(Frame)
	if not Frame:FindFirstChild("InputFrame") then
		warn(`[GAdmin Interface]: _CommandExecution :: Frame '{Frame}' is not considered an argument frame. (No InputFrame has been found.)`)
		return
	end
	
	for i, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	
	self.Connections = {}
	if self.Frame and self.Frame.Parent and self.Frame:FindFirstChild("InputFrame") then
		self.Frame.InputFrame.AutoFill.Visible = false
		for i, Frame in ipairs(self.Frame.InputFrame.AutoFill:GetChildren()) do
			if not Frame:IsA("Frame") then
				continue
			end

			Frame:Destroy()
		end
	end
	
	self.Frame = Frame
	self.AutoFill = nil
	self.Selected = 1
	self.Opened = true
	
	table.insert(self.Connections, self.Frame.InputFrame.Input:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		local Cursor = self.Frame.InputFrame.Input.CursorPosition
		if Cursor < 0 then
			return
		end

		self.Cursor = Cursor
	end))
	
	table.insert(self.Connections, self.Frame.InputFrame.Input:GetPropertyChangedSignal("Text"):Connect(function()
		self:Update()
	end))
	
	table.insert(self.Connections, self.Frame.InputFrame.Input.Focused:Connect(function()
		self.Focused = true
		self:Update()
	end))

	table.insert(self.Connections, self.Frame.InputFrame.Input.FocusLost:Connect(function(EnterPressed)
		self.Focused = false
		self:Update("")
	end))
	
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(InputKey, GameProcessedEvent)
		if InputKey.KeyCode == Enum.KeyCode.Up and self.Opened then
			local Next = self.Selected - 1
			Next = if Next <= 0 then #self.AutoFill else (if Next > #self.AutoFill then 1 else Next)

			self.Selected = Next
			self:UpdateSelected()
		end

		if InputKey.KeyCode == Enum.KeyCode.Down and self.Opened then
			local Next = self.Selected + 1
			Next = if Next <= 0 then #self.AutoFill else (if Next > #self.AutoFill then 1 else Next)

			self.Selected = Next
			self:UpdateSelected()
		end

		if InputKey.KeyCode == Enum.KeyCode.Tab and #self.AutoFill > 0 and self.Focused then
			local Input = self.Frame.InputFrame.Input :: TextBox
			self:SelectFill()
			Input:CaptureFocus()

			task.wait()
			Input.Text = Input.Text:sub(1, #Input.Text - 1)
		end
	end))
end

function Argument:Update(Input)
	self.Input = Input or self.Frame.InputFrame.Input.Text
	for i, Frame in ipairs(self.Frame.InputFrame.AutoFill:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end
	
	self.AutoFill = self:GetAutoFill()
	self.Selected = 1
	
	self.Frame.InputFrame.AutoFill.Visible = true
	for i, Fill in ipairs(self.AutoFill) do
		local Frame = GuiAssets.Fill:Clone()
		Frame.Name = i
		Frame.Content.Text = type(Fill) == "table" and (Fill.Display or Fill.ToFill) or Fill

		Frame.LayoutOrder = i
		Frame.Parent = self.Frame.InputFrame.AutoFill

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

function Argument:UpdateSelected()
	for i, Fill in ipairs(self.AutoFill) do
		local Frame = self.Frame.InputFrame.AutoFill:FindFirstChild(tostring(i))
		if not Frame then
			continue
		end

		local IsSelected = i == self.Selected
		Frame.BackgroundColor3 = IsSelected and Color3.new(0.117647, 0.207843, 0.462745) or Color3.new(0.0823529, 0.145098, 0.329412)
	end
end

function Argument:SelectFill(Selected)
	Selected = Selected or self.Selected
	local Fill = self.AutoFill[Selected]

	if not Fill then
		return
	end

	Fill = type(Fill) == "table" and Fill.ToFill or Fill
	local String, Cursor = AutoFill:Fill(self.Input, self.Cursor, Fill)
	self.Frame.InputFrame.Input.Text = String
	self.Frame.InputFrame.Input.CursorPosition = Cursor
end

function Argument:GetAutoFill(Input)
	local Cursor = self.Frame.InputFrame.Input.CursorPosition
	Input = Input or self.Input

	Input = Input:sub(1, Cursor)
	return AutoFill:Get(Input, self.Command, self.Index)
end

return Argument