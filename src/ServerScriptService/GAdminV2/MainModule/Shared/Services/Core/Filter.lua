--== << Services >>
local TextService = game:GetService("TextService")
--==

local Filter = {}

function Filter:Filter(String, UserId, Type)
	local Filtered = "[Failed to filter message]"
	Type = Type or Enum.TextFilterContext.PublicChat
	
	local Success, Response = pcall(function()
		Filtered = TextService:FilterStringAsync(String, UserId, Type)
	end)

	if not Success then
		return Filtered
	end

	return Filtered:GetNonChatStringForBroadcastAsync()
end

return Filter