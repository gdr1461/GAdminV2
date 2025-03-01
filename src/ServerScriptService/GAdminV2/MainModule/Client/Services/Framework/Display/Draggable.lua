--== << Services >>
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Main = script:FindFirstAncestor("GAdminShared")
local GSignal = require(Main.Shared.Services.GSignalPro)
--==

local Draggables = {}
local Dragging

local Draggable = {}
Draggable.__index = Draggable
Draggable.__type = "GAdmin Draggable"

function Draggable:Enable()
	if self.Enabled then
		return
	end
	
	self.Enabled = true
	local Activated = false
	
	local LastUpdate = 0
	local LastInputKey
	
	table.insert(self.Connections, self.Instance.InputBegan:Connect(function(InputKey)
		if not table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch}, InputKey.UserInputType) then
			return
		end
		
		Dragging = self
		Activated = true
	end))
	
	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(InputKey)
		if not table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch}, InputKey.UserInputType) and (self.Dragging or Activated) then
			return
		end
		
		self.Dragging = false
		self.DragStart = nil
		
		Activated = false
		self.OnEnd:Fire()
	end))
	
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(InputKey)
		if not table.find({Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch}, InputKey.UserInputType) then
			return
		end
		
		self.Dragging = true
		if Activated and Dragging == self then
			self.OnStart:Fire()
			self.DragStart = InputKey.Position
			self.StartPosition = self.Instance.Position
			
			Activated = false
			self.Dragging = true
			LastInputKey = InputKey
		end
		
		--if self.Dragging and self.DragStart then
		--	local Delta = InputKey.Position - self.DragStart
		--	local Position = self.StartPosition + UDim2.fromOffset(Delta.X, Delta.Y)
			
		--	local Object = self.ToDrag or self.Instance
		--	Object.Position = Position
		--end
	end))
	
	table.insert(self.Connections, RunService.RenderStepped:Connect(function()
		local IsDragging = LastInputKey and self.Dragging and self.DragStart
		local Object = self.ToDrag or self.Instance
		
		Object.Interactable = not IsDragging
		if not IsDragging or tick() - LastUpdate < 0.016 then
			return
		end
		
		LastUpdate = tick()
		local Delta = LastInputKey.Position - self.DragStart
		
		local Position = self.StartPosition + UDim2.fromOffset(Delta.X, Delta.Y)
		Object.Position = Object.Position:Lerp(Position, self.Smoothness)
	end))
end

function Draggable:Disable()
	if not self.Enabled then
		return
	end
	
	self.Enabled = false
	for i, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
end

function Draggable:Destroy()
	self:Disable()
	setmetatable(self, nil)
	table.clear(self)
end

return {
	new = function(Object)
		local Drag = setmetatable({}, Draggable)
		Drag.Enabled = false
		
		Drag.Instance = Object
		Drag.Dragging = false
		
		Drag.OnStart = GSignal.new()
		Drag.OnEnd = GSignal.new()
		
		Drag.Connections = {}
		Drag.DragStart = nil
		Drag.StartPosition = nil
		
		Drag.ToDrag = nil
		Drag.Smoothness = .8
		
		return Drag
	end,
}