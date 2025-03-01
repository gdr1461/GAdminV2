--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local WindowAssets = Assets.Windows
local UI = require(Main.Client.Services.UI)

local Sound = require(Main.Shared.Services.Sound)
local GSignal = require(Main.Shared.Services.GSignalPro)

local InputTable = require(Main.Client.Services.Framework.Settings.Inputs)
local Display = require(Main.Client.Services.Framework.Display)
--==

local Windows = {}
local Window = {}

Window.__index = Window
Window.__type = "GAdmin Window"

function Window:Update()
	self.Instance.Top.Title.Text = self.Title
	self.Instance.Name = `{self.Type}-{self.Title}`
	self.Instance.UIScale.Scale = self.Size
end

function Window:SetTitle(Title)
	Title = Title or ""
	self.Title = Title
	self:Update()
end

function Window:SetSize(Amount)
	Amount = math.clamp(Amount, 1, 2)
	self.Size = Amount
	self:Update()
end

function Window:AddInputs(Inputs)
	local Indices = {}
	for i, Input in ipairs(Inputs) do
		local Index = self:AddInput(Input)
		if not Index then
			continue
		end

		table.insert(Indices, Index)
	end
	
	return Indices
end

function Window:AddInput(Input)
	if type(Input) ~= "table" or not Input.Activated or not Input.Title or not Input.Type then
		warn(`[{self.__type}]: {self.Title} :: Input invalid.`)
		return
	end
	
	local Frame = WindowAssets.Inputs:FindFirstChild(Input.Type)
	if not Frame or not InputTable[Input.Type] then
		warn(`[{self.__type}]: {self.Title} :: Input invalid.`)
		return
	end
	
	local Cache = {
		Title = Input.Title,
		Activated = Input.Activated,
		State = Input.State,
		Default = Input.Default or Input.State,
		Instance = Frame:Clone(),
		TitleInstance = WindowAssets.Input:Clone(),
		GapInstance = WindowAssets.Gap:Clone(),
		
		Key = Input.Key,
		Connections = {},
	}
	
	local Request = {
		Object = Cache.Instance,
		Default = Cache.Default,
	}
	
	Cache.SetState = function(State)
		Cache.State = State
		InputTable[Input.Type].Set(Request, Cache.State)
		Cache.Activated(Cache)
	end
	
	Cache.TitleInstance.Title.Text = Cache.Title
	Cache.TitleInstance.Parent = self.Instance.Inputs
	
	Cache.Instance.Parent = self.Instance.Inputs
	Cache.GapInstance.Parent = self.Instance.Inputs
	
	Cache.Connections = InputTable[Input.Type].Connect(Request, function(Value)
		Cache.State = Value
		Cache.Activated(Cache)
	end)
	
	Request.Connections = Cache.Connections
	InputTable[Input.Type].Set(Request, Cache.State)
	table.insert(self.Inputs, Cache)
	
	self:Update()
	return #self.Inputs
end

function Window:FindInput(Index)
	return self.Inputs[Index]
end

function Window:RemoveInput(Index)
	local Cache = self.Inputs[Index]
	if not Cache then
		warn(`[{self.__type}]: {self.Title} :: Input with index '{Index}' is invalid.`)
		return
	end
	
	for i, Connection in pairs(Cache.Connections) do
		if typeof(Connection) == "RBXScriptSignal" then
			Connection:Disconnect()
			continue
		end
		
		if type(Connection) == "table" and Connection.Destroy then
			Connection:Destroy()
		end
	end
	
	Cache.Instance:Destroy()
	Cache.TitleInstance:Destroy()
	Cache.GapInstance:Destroy()
	
	Cache.Connections = {}
	table.remove(self.Inputs, Index)
end

function Window:Destroy()
	self.Destroying:Fire()
	local Index = table.find(Windows, self)
	
	if Index then
		table.remove(Windows, Index)
	end
	
	for i, Cache in ipairs(self.Inputs) do
		self:RemoveInput(i)
	end
	
	for i, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	
	self.Destroying:Destroy()
	self.Draggable:Destroy()
	self.Instance:Destroy()
	
	setmetatable(self, nil)
	table.clear(self)
end

return {
	new = function(Type)
		local Frame = WindowAssets.Windows:FindFirstChild(Type)
		if not Frame then
			warn(`[{Window.__type}]: Type '{Type}' is invalid.`)
			return
		end
		
		local NewWindow = setmetatable({}, Window)
		NewWindow.Connections = {}
		NewWindow.Destroying = GSignal.new()
		
		NewWindow.Type = Type
		NewWindow.Inputs = {}
		NewWindow.Size = 1
		
		NewWindow.Instance = Frame:Clone()
		NewWindow.Instance.Parent = UI.Gui.Windows
		
		NewWindow.Draggable = Display.Draggable(Instance.new("BoolValue"), NewWindow.Instance)
		NewWindow.Draggable:Enable()
		
		table.insert(NewWindow.Connections, NewWindow.Instance.Top.Close.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end))
		
		table.insert(NewWindow.Connections, NewWindow.Instance.Top.Close.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			NewWindow:Destroy()
		end))
		
		table.insert(NewWindow.Connections, UserInputService.InputBegan:Connect(function(InputKey, GameProcessedEvent)
			if GameProcessedEvent then
				return
			end
			
			for i, Input in ipairs(NewWindow.Inputs) do
				if not Input.Key or not Input.Key.Key or not Input.Key.Activated or (InputKey.KeyCode ~= Input.Key.Key and InputKey.UserInputType ~= Input.Key.Key) then
					continue
				end
				
				Input.Key.Activated(Input)
			end
		end))
		
		NewWindow:SetTitle("N/A")
		table.insert(Windows, NewWindow)
		return NewWindow
	end,
	
	Find = function(Type, Title)
		for i, Window in ipairs(Windows) do
			if Window.Type ~= Type or Window.Title ~= Title then
				continue
			end
			
			return Window
		end
	end,
}