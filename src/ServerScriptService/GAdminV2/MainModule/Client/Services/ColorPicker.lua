--[[

	Modified for GAdmin v2 by @gdr1461account2.

	Color Picker Module by @Brambes230605.

]]

local Main = script:FindFirstAncestor("GAdminShared")
local GSignal = require(Main.Shared.Services.GSignalPro)

local Sound = require(Main.Shared.Services.Sound)
local Draggable = require(Main.Client.Services.Framework.Display.Draggable)

export type ColorPicker = {
	currentColor: Color3,
	active: boolean,
	Opened: RBXScriptSignal,
	Closed: RBXScriptSignal,
	Changed: RBXScriptSignal,
	SetColor: (self: ColorPicker, color: Color3) -> (),
	GetColor: (self: ColorPicker) -> Color3,
	Start: (self: ColorPicker) -> (),
	Cancel: (self: ColorPicker) -> (),
	Destroy: (self: ColorPicker) -> (),
}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = require(Main.Client.Services.UI).Gui

function updateColor(self, arg1: Color3 | number, arg2: number?, arg3: number?)
	
	local hue: number
	local sat: number
	local val: number
	
	if typeof(arg1) == "Color3" then
		hue, sat, val = arg1:ToHSV()
		self.currentColor = arg1
	elseif arg1 and arg2 and arg3 then
		hue = arg1 :: number
		sat = arg2 --or 0
		val = arg3 --or 0
		self.currentColor = Color3.fromHSV(hue, sat, val)
	end
	
	self.previewColor.BackgroundColor3 = self.currentColor
	
	local function updateTextBoxNumber(textBox: TextBox, value: number | string, multiplier: number?)
		local text: string
		if typeof(value) == "number" and multiplier then
			text = tostring(math.round(value * multiplier))
		else
			text = value :: string
		end
		textBox.Text = text
		textBox.PlaceholderText = text
	end

	updateTextBoxNumber(self.textBoxNumber.Hue, hue, 359)
	updateTextBoxNumber(self.textBoxNumber.Saturation, sat, 255)
	updateTextBoxNumber(self.textBoxNumber.Value, val, 255)

	updateTextBoxNumber(self.textBoxNumber.Red, self.currentColor.R, 255)
	updateTextBoxNumber(self.textBoxNumber.Green, self.currentColor.G, 255)
	updateTextBoxNumber(self.textBoxNumber.Blue, self.currentColor.B, 255)
	
	local hex = self.currentColor:ToHex()
	updateTextBoxNumber(self.textBoxNumber.HTML, hex)
	
	self.valUiGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, 1))
	})
	self.valueCursor.Position = UDim2.fromScale(0, 1 - val)
	self.colorCursor.Position = UDim2.fromScale(1 - hue, 1 - sat)
	
	self.Changed:Fire(self.currentColor)
end

local function connectEvents(self)
	
	local function Update()
		local absoluteColorPos: Vector2 = self.colorButton.AbsolutePosition
		local absoluteColorSize: Vector2 = self.colorButton.AbsoluteSize
		self.min_x = absoluteColorPos.X
		self.max_x = absoluteColorPos.X + absoluteColorSize.X
		self.min_y = absoluteColorPos.Y + GuiService.TopbarInset.Height
		self.max_y = absoluteColorPos.Y + absoluteColorSize.Y + GuiService.TopbarInset.Height
	end

	self.colorButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(Update)
	self.colorButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(Update)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(Update)

	self.colorButton.MouseButton1Down:Connect(function()

		while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and self.active do
			
			local mousePos = UserInputService:GetMouseLocation()

			local percent_x = 1 - math.clamp((mousePos.X - self.min_x) / (self.max_x - self.min_x), 0, 1)
			local percent_y = 1 - math.clamp((mousePos.Y - self.min_y) / (self.max_y - self.min_y), 0, 1)
			
			self.hue = percent_x
			self.sat = percent_y
			
			updateColor(self, self.hue, self.sat, self.val)
			task.wait()
		end
	end)
	
	local function dragValue()
		while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and self.active do
			
			local mousePos = UserInputService:GetMouseLocation()
			
			local percent = 1 - math.clamp((mousePos.Y - self.min_y) / (self.max_y - self.min_y), 0, 1)
			self.val = percent
			
			updateColor(self, self.hue, self.sat, self.val)
			task.wait()
		end
	end

	self.valueButton.MouseButton1Down:Connect(dragValue)
	self.valueCursor.TextButton.MouseButton1Down:Connect(dragValue)

	self.okButton.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	self.okButton.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self.frame.Visible = false
		self.active = false
		self.Closed:Fire(self.currentColor, true)
	end)
	
	self.cancelButton.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	self.cancelButton.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self.frame.Visible = false
		self.active = false
		updateColor(self, self.currentColor)
		self.Closed:Fire(self.currentColor, false)
	end)
	
	local function ProcessText(enterPressed: boolean, number: string): number?
		local newNumber = tonumber(number)
		if not newNumber then
			updateColor(self, self.currentColor)
			return nil
		end
		return newNumber
	end
	
	self.textBoxNumber.Red.FocusLost:Connect(function(enterPressed: boolean)
		local r = ProcessText(enterPressed, self.textBoxNumber.Red.Text)
		if not r then return end
		r = math.clamp(r, 0, 255) / 255
		local g, b = self.currentColor.G, self.currentColor.B
		updateColor(self, Color3.new(r, g, b))
	end)
	
	self.textBoxNumber.Green.FocusLost:Connect(function(enterPressed: boolean)
		local g = ProcessText(enterPressed, self.textBoxNumber.Green.Text)
		if not g then return end
		g = math.clamp(g, 0, 255) / 255
		local r, b = self.currentColor.R, self.currentColor.B
		updateColor(self, Color3.new(r, g, b))
	end)
	
	self.textBoxNumber.Blue.FocusLost:Connect(function(enterPressed: boolean)
		local b = ProcessText(enterPressed, self.textBoxNumber.Blue.Text)
		if not b then return end
		b = math.clamp(b, 0, 255) / 255
		local r, g = self.currentColor.R, self.currentColor.G
		updateColor(self, Color3.new(r, g, b))
	end)
	
	self.textBoxNumber.Hue.FocusLost:Connect(function(enterPressed: boolean)
		local hue = ProcessText(enterPressed, self.textBoxNumber.Hue.Text)
		if not hue then return end
		self.hue = math.clamp(hue, 0, 359) / 359
		updateColor(self, self.hue, self.sat, self.val)
	end)
	
	self.textBoxNumber.Saturation.FocusLost:Connect(function(enterPressed: boolean)
		local sat = ProcessText(enterPressed, self.textBoxNumber.Saturation.Text)
		if not sat then return end
		self.sat = math.clamp(sat, 0, 255) / 255
		updateColor(self, self.hue, self.sat, self.val)
	end)
	
	self.textBoxNumber.Value.FocusLost:Connect(function(enterPressed: boolean)
		local val = ProcessText(enterPressed, self.textBoxNumber.Value.Text)
		if not val then return end
		self.val = math.clamp(val, 0, 255) / 255
		updateColor(self, self.hue, self.sat, self.val)
	end)
	
	self.textBoxNumber.HTML.FocusLost:Connect(function()
		local success, result = pcall(function()
			return Color3.fromHex(self.textBoxNumber.HTML.Text)
		end)
		if success then
			updateColor(self, result)
		else
			updateColor(self, self.currentColor)
		end
	end)
end

local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(IsDraggable): ColorPicker
	local self = setmetatable({}, ColorPicker)
	
	self.currentColor = Color3.new(1, 1, 1)
	self.active = false
	
	self.Opened = GSignal:Create()
	self.Closed = GSignal:Create()
	self.Changed = GSignal:Create()
	
	self.hue, self.sat, self.val = self.currentColor:ToHSV()
	
	self.frame = script.Main:Clone()
	self.frame.Name = tostring(#screenGui.ColorPickers:GetChildren()+1)
	self.frame.Parent = screenGui.ColorPickers
	self.sliders = self.frame.Sliders
	self.numeric = self.frame.Numeric
	
	self.previewColor = self.numeric.Preview
	self.okButton = self.numeric.Ok
	self.cancelButton = self.numeric.Cancel
	self.textBoxNumber = self.numeric.TextBox
	self.colorButton = self.sliders.Color.Button
	self.colorCursor = self.sliders.Color.White.Cursor
	self.valueButton = self.sliders.Value.Button
	self.valueCursor = self.sliders.Value.Cursor
	self.valUiGradient = self.sliders.Value.UIGradient
	
	updateColor(self, self.currentColor)
	
	connectEvents(self)
	
	if IsDraggable then
		self.Draggable = Draggable.new(self.frame)
	end

	return self
end

function ColorPicker:SetColor(color: Color3)
	if not color then
		error("Argument 1 missing or nil", 2)
	elseif color and typeof(color) ~= "Color3" then
		error("Color3 expected got " .. typeof(color), 2)
	elseif color then
		self.hue, self.sat, self.val = color:ToHSV() -- new color, need to reset hue, sat, val
		updateColor(self, self.hue, self.sat, self.val)
	end
end

function ColorPicker:GetColor(): Color3
	return self.currentColor
end

function ColorPicker:Start()
	if self.active then return end
	self.frame.Visible = true
	self.active = true
	self.Opened:Fire()
	
	if self.Draggable then
		self.Draggable:Enable()
	end
end

function ColorPicker:Cancel()
	if not self.active then return end
	self.frame.Visible = false
	self.active = false
	self.Closed:Fire(self.currentColor)
	
	if self.Draggable then
		self.Draggable:Disable()
	end
end

function ColorPicker:Destroy()
	self.active = false
	self.Changed:Destroy()
	self.Opened:Destroy()
	self.Closed:Destroy()
	self.frame:Destroy()
	
	if self.Draggable then
		self.Draggable:Destroy()
	end
	
	setmetatable(self, nil)
	table.clear(self)
end

return ColorPicker
