--== << Services >>
local RunService = game:GetService("RunService")
local Main = script:FindFirstAncestor("GAdminShared")

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
local Builds = require(script.Builds)
--==

local Hover = {}
Hover.__index = Hover
Hover.__type = "GAdmin FancyHover"

function Hover:__tostring()
	return self.__type
end

function Hover:Apply(NoAuto)
	if NoAuto and table.find({"TextButton", "ImageButton"}, self.Object.ClassName) then
		self.Object.AutoButtonColor = false
	end

	table.insert(self.__Connections, self.Object.MouseEnter:Connect(function()
		self:Enable()
	end))
	
	table.insert(self.__Connections, self.Object.MouseLeave:Connect(function()
		self:Disable()
	end))
end

function Hover:Reset()
	self.Hover.Gradient.Rotation = -180
end

function Hover:Enable()
	if self.Enabled then
		return
	end
	
	self:Reset()
	self.Enabled = true
	self.Hover.Enabled = true
end

function Hover:Disable()
	if not self.Enabled then
		return
	end
	
	self:Reset()
	self.Enabled = false
	self.Hover.Enabled = false
end

function Hover:Destroy()
	for i, Connection in ipairs(self.__Connections) do
		Connection:Disconnect()
	end
	
	self.Hover:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

return {
	new = function(GuiObject, Color)
		if GuiObject:FindFirstChild("FancyHover") then
			return
		end
		
		if type(Color) == "string" and Builds[Color] then
			Color = Builds[Color]
		end
		
		local HoverObject = GuiAssets.FancyHover:Clone()
		Color = Color or HoverObject.Gradient.Color
		
		local Sequence = typeof(Color) == "ColorSequence" and Color or ColorSequence.new(Color)
		HoverObject.Gradient.Color = Sequence
		HoverObject.Parent = GuiObject
		
		local NewHover = setmetatable({}, Hover)
		NewHover.__Connections = {}
		
		NewHover.Hover = HoverObject
		NewHover.Object = GuiObject
		
		NewHover.Enabled = false
		NewHover.Speed = 1
	
		table.insert(NewHover.__Connections, _G.GAdmin.Render(function(Delta)
			if not NewHover or not NewHover.Enabled or not HoverObject or not HoverObject.Parent then
				return
			end
			
			local Rotation = HoverObject.Gradient.Rotation + (360 * NewHover.Speed * Delta)
			Rotation = Rotation > 180 and -180 or Rotation
			HoverObject.Gradient.Rotation = Rotation
		end))
		
		return NewHover
	end,
}