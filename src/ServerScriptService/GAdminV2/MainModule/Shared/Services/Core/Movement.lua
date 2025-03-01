--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
--==

if not player then
	return {
		"Cannot access client only module from server side.",
		Incompatible = true,
	}
end

local Movement = {}
Movement.KeyPressed = {}

Movement.Translator = {
	{
		Name = "Forwards",
		Keys = {Enum.KeyCode.W, Enum.KeyCode.Up}
	},
	
	{
		Name = "Backwards",
		Keys = {Enum.KeyCode.S, Enum.KeyCode.Down}
	},
	
	{
		Name = "Right",
		Keys = {Enum.KeyCode.D, Enum.KeyCode.Right}
	},
	
	{
		Name = "Left",
		Keys = {Enum.KeyCode.A, Enum.KeyCode.Left}
	},
	
	{
		Name = "Up",
		Keys = {Enum.KeyCode.Space, Enum.KeyCode.R}
	},
	
	{
		Name = "Down",
		Keys = {Enum.KeyCode.Q, Enum.KeyCode.F, Enum.KeyCode.LeftControl}
	},
}

function Movement:Load()
	UserInputService.InputBegan:Connect(function(InputKey, GameProcessedEvent)
		if GameProcessedEvent then
			return
		end
		
		local IsUnknown = InputKey.KeyCode == Enum.KeyCode.Unknown
		local Key = IsUnknown and InputKey.UserInputType or InputKey.KeyCode
		table.insert(Movement.KeyPressed, Key)
	end)
	
	UserInputService.InputEnded:Connect(function(InputKey)
		local IsUnknown = InputKey.KeyCode == Enum.KeyCode.Unknown
		local Key = IsUnknown and InputKey.UserInputType or InputKey.KeyCode
		
		local Index = table.find(self.KeyPressed, Key)
		if not Index then
			return
		end
		
		table.remove(self.KeyPressed, Index)
	end)
end

function Movement:Translate(Key)
	for i, Translation in ipairs(self.Translator) do
		if not table.find(Translation.Keys, Key) then
			continue
		end
		
		return Translation.Name
	end
end

function Movement:Next(Delta, Speed)
	local Next = Vector3.new()
	local Directions = {
		Left = Vector3.new(-1, 0, 0),
		Right = Vector3.new(1, 0, 0),
		Forwards = Vector3.new(0, 0, -1),
		Backwards = Vector3.new(0, 0, 1),
		Up = Vector3.new(0, 1, 0),
		Down = Vector3.new(0, -1, 0),
	}
	
	local Character = player.Character
	local Humanoid = Character.Humanoid
	local RootPart = Character.HumanoidRootPart
	
	if self.Core.Device:Get() == "Computer" then
		for i, Key in pairs(self.KeyPressed) do
			local Direction = self:Translate(Key)
			if not Directions[Direction] then
				continue
			end
			
			Next = Next + Directions[Direction]
		end
		
		return CFrame.new(Next * Speed * Delta), Next
	end
	
	if not Humanoid then
		return
	end
	
	local MoveDirection = Humanoid.MoveDirection
	for Name, Vector in pairs(Directions) do
		local isFor = false
		if Name == "Forwards" or Name == "Backwards" then
			isFor = true
		end

		local Position = ((RootPart.CFrame * CFrame.new(Vector)) - RootPart.Position).Position
		local Distance = (Position - MoveDirection).Magnitude

		if Distance <= 1.05 and MoveDirection ~= Vector3.new(0,0,0) then
			Next = Next + Vector
		end
	end
	
	return CFrame.new(Next * Speed * Delta), Next
end

return Movement