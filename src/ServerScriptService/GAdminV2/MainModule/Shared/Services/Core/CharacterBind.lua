--== << Services >>
local Players = game:GetService("Players")
--==

local Binds = {}

Players.PlayerRemoving:Connect(function(player)
	if not Binds[player.UserId] then
		return
	end
	
	Binds[player.UserId].Connection:Disconnect()
	Binds[player.UserId] = nil
end)

return function(player, Name, Function)
	Binds[player.UserId] = Binds[player.UserId] or {
		Binds = {},
		Connection = player.CharacterAdded:Connect(function(Character)
			for i, Function in pairs(Binds[player.UserId].Binds) do
				coroutine.wrap(Function)(Character)
			end
		end),
	}
	
	Binds[player.UserId].Binds[Name] = Function
end