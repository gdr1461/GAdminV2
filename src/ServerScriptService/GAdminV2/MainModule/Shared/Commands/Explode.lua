--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
--==

local Command = {}
Command.Order = 24

Command.Name = "Explode"
Command.Alias = {"Explosion"}
Command.Description = "Explodes specified player."

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
	
	local Explosion = Instance.new("Explosion")
	Explosion.Position = RootPart.Position
	Explosion.DestroyJointRadiusPercent = 0
	
	Explosion.Parent = player.Character
	player.Character:BreakJoints()
end

return Command