--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")
local GSignal = require(Main.Shared.Services.GSignalPro)
--==

local Slider = {}
Slider.__index = Slider
Slider.__type = "GAdmin Slider"

function Slider:Update()
	if self.Value == self.__OldValue then
		return
	end
	
	local Value = tonumber(string.format("%.2f", self.Value))
	self.Frame.Input.Text = Value
	self.Frame.Limits.Slide.Position = UDim2.fromScale(self.__Position, .5)
	
	self.__OldValue = self.Value
	self.OnUpdate:Fire(Value)
end

function Slider:SetSlide(Value)
	Value = math.clamp(Value, 0, self.Max)
	self.Divisions = Value
	self:Update()
end

function Slider:Set(Value, NoDivisions)
	Value = math.clamp(Value, self.Min, self.Max)
	Value = NoDivisions and Value or math.round(Value / self.Divisions) * self.Divisions
	
	self.__Position = Value / self.Max
	self.Value = Value
	self:Update()
end

function Slider:Destroy()
	self.OnDrag:Destroy()
	self.OnDragEnded:Destroy()
	self.OnUpdate:Destroy()
	
	for i, Connection in ipairs(self.__Connections) do
		Connection:Disconnect()
	end
	
	setmetatable(self, nil)
	table.clear(self)
end

return {
	new = function(Frame, Min, Max)
		Min = Min or 0
		Max = Max or 1
		
		if Min >= Max then
			warn(`[GAdmin Slider]: Min value can not be bigger or equals to the Max value.`)
			return
		end
		
		local NewSlider = setmetatable({}, Slider)
		NewSlider.Dragging = false
		NewSlider.Value = Min
		
		NewSlider.Frame = Frame
		NewSlider.Divisions = .1
		
		NewSlider.Min = Min
		NewSlider.Max = Max
		
		NewSlider.OnUpdate = GSignal.new()
		NewSlider.OnDrag = GSignal.new()
		NewSlider.OnDragEnded = GSignal.new()
		
		NewSlider.__OldValue = Min
		NewSlider.__Position = Min
		NewSlider.__Connections = {}
		
		table.insert(NewSlider.__Connections, Frame.Input.FocusLost:Connect(function()
			local Input = Frame.Input.Text
			local Value = tonumber(Input)
			
			if not Value then
				Frame.Input.Text = NewSlider.Value
				return
			end
			
			NewSlider:Set(Value, true)
		end))
		
		table.insert(NewSlider.__Connections, Frame.Limits.Slide.MouseButton1Down:Connect(function()
			NewSlider.Dragging = true
			NewSlider.OnDrag:Fire()
		end))
		
		table.insert(NewSlider.__Connections, Frame.Limits.Slide.MouseButton1Up:Connect(function()
			NewSlider.Dragging = false
			NewSlider.OnDragEnded:Fire()
		end))
		
		table.insert(NewSlider.__Connections, UserInputService.InputEnded:Connect(function(InputKey)
			if InputKey.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			
			NewSlider.Dragging = false
		end))
		
		table.insert(NewSlider.__Connections, UserInputService.InputChanged:Connect(function(InputKey)
			if InputKey.UserInputType ~= Enum.UserInputType.MouseMovement or not NewSlider.Dragging then
				return
			end
			
			local Position = UserInputService:GetMouseLocation()
			local Relative = Position - Frame.Limits.AbsolutePosition
			local Size = Frame.Limits.AbsoluteSize
			
			local Result = math.clamp(Relative.X / Size.X, 0, 1)
			NewSlider:Set(Result * NewSlider.Max)
		end))
		
		NewSlider:Update()
		return NewSlider
	end,
}