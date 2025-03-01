--== << Services >>
local Side = game.Players.LocalPlayer == nil and "Server" or "Client"
local PhysicsService = Side == "Server" and game:GetService("PhysicsService") or nil
--==

local Collision = {}

function Collision:Load()
	if Side == "Client" then
		return
	end
	
	PhysicsService:RegisterCollisionGroup("GA_Noclip")
	for i, Group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		if table.find({"GA_Noclip"}, Group.name) then
			continue
		end
		
		PhysicsService:CollisionGroupSetCollidable("GA_Noclip", Group.name, false)
	end
end

function Collision:Recursive(Holder, Group)
	for i, Object in ipairs(Holder:GetDescendants()) do
		self:Set(Object, Group)
	end
end

function Collision:Set(Object, Group)
	if not Object:IsA("BasePart") then
		return
	end
	
	Object.CollisionGroup = Group
end

return Collision