--== << Services >>
local Debris = game:GetService("Debris")
local Main = script:FindFirstAncestor("GAdminShared")
--==

local Command = {}
Command.Order = 19

Command.Name = "Fling"
Command.Alias = {"ToSpace"}
Command.Description = "Flings specified player away."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,

		Flags = {"Optional", "PlayerOnline"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1] or Caller
	local RootPart = player.Character.HumanoidRootPart
	local Humanoid = player.Character.Humanoid
	
	local CallerPosition = Caller.Character.HumanoidRootPart.Position
	local Position = RootPart.Position
	
	local Distance = 50
	local BodyPosition = Instance.new("BodyPosition")
	
	BodyPosition.Name = "GAFling1"
	BodyPosition.MaxForce = Vector3.new(10000000, 10000000, 10000000)
	
	BodyPosition.D = 450
	BodyPosition.P = 10000
	
	if player == Caller then
		Position = (RootPart.CFrame * CFrame.new(0,0,-4)).Position
	end
	
	local Unit = (Position - CallerPosition).Unit
	BodyPosition.Position = Position + Vector3.new(Unit.X, 1.4, Unit.Z) * Distance
	
	local BodyVelocity = Instance.new("BodyAngularVelocity")
	BodyVelocity.Name = "GAFling2"
	BodyVelocity.MaxTorque = Vector3.new(300000, 300000, 300000)
	
	BodyVelocity.P = 300
	BodyVelocity.AngularVelocity = Vector3.new(10, 10 ,10)
	
	BodyVelocity.Parent = RootPart
	BodyPosition.Parent = RootPart
	
	Debris:AddItem(BodyVelocity, 0.1)
	Debris:AddItem(BodyPosition, 0.1)
	
	Humanoid.PlatformStand = true
	task.delay(5, function()
		Humanoid.PlatformStand = false
	end)
end

return Command