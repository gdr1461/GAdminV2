function SetSettings(player, PlayerSettings, Settings)
	for Key, Value in pairs(Settings) do
		local PlayerValue = PlayerSettings[Key]
		if type(PlayerValue) ~= type(Value) and not (PlayerValue == nil and type(Value) == "boolean") then
			return false, `Setting '{Key}' must be a type of '{type(PlayerValue)}'`
		end
		
		if type(Value) == "table" then
			local Success, Response = SetSettings(player, PlayerSettings[Key], Value)
			if Success then
				continue
			end
			
			return Success, Response
		end
	end
	
	return true
end

local CustomHandler = {
	Prefix = function(Value)
		return type(Value) == "string"
	end,
	
	Defaults = function(Value)
		if type(Value) ~= "table" then
			return false
		end
		
		local Whitelist = {
			BanMessage = "string",
			KickMessage = "string"
		}
		
		for Key, KeyValue in pairs(Value) do
			if Whitelist[Key] and type(KeyValue) == Whitelist[Key] then
				continue
			end
			
			return false
		end
		
		return true
	end,
}

function SetCustom(player, Session, Custom)
	for Key, Request in pairs(Custom) do
		if Session[Request[1]] and CustomHandler[Request[1]] and CustomHandler[Request[1]](Request[2]) then
			Session[Request[1]] = Request[2]
			continue
		end
		
		return false, "Invalid request custom data."
	end
	
	return true, Session
end

return {
	SetSettings = SetSettings,
	SetCustom = SetCustom,
}