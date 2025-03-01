local Time = {}
Time.Content = {
	{
		Name = "Years",
		Add = 31536000
	},

	{
		Name = "Days",
		Add = 86400,
	},

	{
		Name = "Hours",
		Add = 3600,
	},

	{
		Name = "Minutes",
		Add = 60,
	},

	{
		Name = "Seconds",
		Add = 1
	},
}

function Time:GetTime(Seconds, NoModulus)
	if NoModulus then
		return {
			Year = math.floor(Seconds / 31536000),
			Month = math.floor(Seconds / 2629746),
			Day = math.floor(Seconds % 2629746 / 86400),
			Hour = math.floor(Seconds / 3600),
			Minute = math.floor(Seconds / 60),
			Second = math.floor(Seconds)
		}
	end
	
	return {
		Year = math.floor(Seconds / 31536000),
		Month = math.floor(Seconds % 31536000 / 2629746),
		Day = math.floor(Seconds % 31536000 % 2629746 / 86400),
		Hour = math.floor(Seconds % 31536000 % 2629746 % 86400 / 3600),
		Minute = math.floor(Seconds % 31536000 % 2629746 % 86400 % 3600 / 60),
		Second = math.floor(Seconds % 31536000 % 2629746 % 86400 % 3600 % 60)
	}
end

function Time:Format(Timestamp, Format)
	local Parts = {}

	for i, Info in ipairs(Format.Units) do
		local Value = Timestamp[Info.Unit]
		if not Value or Value <= 0 then
			continue
		end
		
		table.insert(Parts, string.format(Info.Format, Value))
	end

	return table.concat(Parts, Format.Divider)
end

function Time:GetSeconds(String, Divider)
	local Split = String:split(Divider)
	local Seconds = 0
	
	for i, Word in ipairs(Split) do
		if Word:gsub("%s+", "") == "" then
			continue
		end

		local AmountRaw = Word:gsub("%D", "")
		local Amount = tonumber(AmountRaw)
		
		if not Amount then
			return false
		end

		local Prefix = Word:gsub("%d", ""):gsub("%W", "")
		if Prefix == "" then
			return false
		end
		
		local PrefixInfo = self:FindPrefix(Prefix)
		if not PrefixInfo then
			return false
		end
		
		Seconds += PrefixInfo.Add * Amount
	end
	
	return true, Seconds
end

function Time:FindPrefix(Prefix: string)
	for i, PrefixInfo in ipairs(self.Content) do
		if PrefixInfo.Name:lower():sub(1, #Prefix) ~= Prefix:lower() then
			continue
		end
		
		return PrefixInfo
	end
end

return Time