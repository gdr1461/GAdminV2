local Settings = {}
Settings.Settings = {}

function Settings:SetPlayer(player, Settings)
	for i, v in pairs(self.Settings) do
		if Settings[i] ~= nil then
			continue
		end
		
		Settings[i] = v
	end
	
	return Settings
end

function Settings:Set(Name, Value)
	self.Settings[Name] = Value
	for i, player in ipairs(game.Players:GetPlayers()) do
		self.PlayerAPI.Players[player.UserId].Data.Settings = self:SetPlayer(player, self.PlayerAPI.Players[player.UserId].Data.Settings)
	end
end

return Settings