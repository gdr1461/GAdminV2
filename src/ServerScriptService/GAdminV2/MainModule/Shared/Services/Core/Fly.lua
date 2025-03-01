--== << Services >>
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
--==

local Fly = {}
Fly.Modes = {"Fly", "Noclip"}
Fly.Custom = {}

Fly.Settings = {
	{
		Name = "Fly",
		Velocity = 200,
		Speed = 50
	},

	{
		Name = "Noclip",
		Velocity = 2000,
		Speed = 50,
	},
}

function Fly:Load()
	coroutine.wrap(function()
		local Update = tick()
		while true do
			if not self.Cycle then
				Update = tick()
				task.wait()
				continue
			end

			local Delta = tick() - Update
			self.Cycle(Delta)

			Update = tick()
			task.wait()
		end
	end)()
end

function Fly:SetSpeed(player, Mode, Speed)
	self.Custom[player.UserId] = self.Custom[player.UserId] or {}
	self.Custom[player.UserId][Mode] = Speed
end

function Fly:Enable(player, Mode)
	local ModeId = table.find(self.Modes, Mode)
	if not ModeId then
		warn(`[GAdmin Fly]: Mode '{Mode}' is invalid.`)
		return
	end

	local Character = player.Character
	local Humanoid = Character.Humanoid
	local RootPart = Character.HumanoidRootPart

	self:Disable(player)
	local Force = Instance.new("BodyPosition")

	Force.Name = "GA_Position"
	Force.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	Force.Position = RootPart.Position + Vector3.new(0, 4, 0)
	Force.Parent = RootPart

	local Orientation = Instance.new("BodyGyro")
	Orientation.Name = "GA_Orientation"
	Orientation.D = 50
	Orientation.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	Orientation.P = self.Settings[ModeId].Velocity

	Orientation.CFrame = RootPart.CFrame
	Orientation.Parent = RootPart

	local IsNoclip = ModeId == 2
	local MaxTilt = 25
	local Tilt = 0
	local Static = 0

	if IsNoclip then
		self.Core.Collision:Recursive(Character, "GA_Noclip")
	end

	local LastPosition = RootPart.Position
	Humanoid.PlatformStand = true
	
	self.Cycle = function(Delta)
		if not Humanoid or not RootPart then
			self:Disable()
			return
		end

		local Unit = (Camera.Focus.Position - Camera.CFrame.Position).Unit
		local Speed = self.Custom[player.UserId] and self.Custom[player.UserId][Mode] or self.Settings[ModeId].Speed

		local Movement, Direction = self.Core.Movement:Next(Delta, Speed * 25)
		local Position = RootPart.Position

		local TargetCFrame = CFrame.new(Position, Position + Unit) * Movement
		local Damping = 750 + (Speed * 0.2)

		if IsNoclip then
			--Damping /= 2
		end

		if Movement.Position ~= Vector3.new() then
			Static = 0
			Force.D = Damping
			Tilt += 1
			Force.Position = TargetCFrame.Position
		else
			Static += 1
			Tilt = 1

			local Distance = (RootPart.Position - LastPosition).Magnitude
			if Distance > 6 and Static >= 4 then
				Force.Position = RootPart.Position
			end
		end
		
		Tilt = math.min(Tilt, MaxTilt)
		if Force.D == Damping then
			local ZTilt = IsNoclip and 0 or Tilt * Direction.Z
			Orientation.CFrame = TargetCFrame * CFrame.Angles(math.rad(ZTilt), 0, 0)
		end

		LastPosition = RootPart.Position
		if Humanoid then
			Humanoid.PlatformStand = true
		end
	end
end

function Fly:Disable(player)
	local Character = player.Character
	local RootPart = Character.HumanoidRootPart

	self.Cycle = nil
	player.Character.Humanoid.PlatformStand = false
	self.Core.Collision:Recursive(Character, "Default")

	local PreviousForce = RootPart:FindFirstChild("GA_Position")
	local PreviousOrientation = RootPart:FindFirstChild("GA_Orientation")

	if PreviousForce then
		PreviousForce:Destroy()
	end

	if PreviousOrientation then
		PreviousOrientation:Destroy()
	end
end

return Fly