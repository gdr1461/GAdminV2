local Logs = require(script.Logs)
function GetVersionNumber(Version)
	local VersionNumber = 0
	local PrefixSplit = Version:split("-")

	local Prefix = #PrefixSplit > 1 and PrefixSplit[1] or nil
	local Splitted = (#PrefixSplit > 1 and Prefix[2] or PrefixSplit[1]):gsub("%a+", ""):split(".")

	local Multipliers = {100, 10, 1}
	for Index, Number in ipairs(Splitted) do
		Number = tonumber(Number, 10)
		if not Number then
			continue
		end

		Number *= Multipliers[Index] or 1
		VersionNumber += Number
	end

	return VersionNumber, Prefix
end

return {
	Description = "GAdmin v2 config file which is used to check the installed version of GAdmin with the up-to-date one.",
	Version = "BETA-v2.0.0",

	Supported = {},
	Logs = Logs,

	AssetId = 133496558665233,
	Donations = {2677352233, 2677352322, 2677352402, 2677352627},
	
	Prefixes = {"", "TEST", "BETA", "ALPHA", "INDEV"},
	Internals = {1556153247},

	Check = function(self, Version)
		local Supported = table.clone(self.Supported)
		table.insert(Supported, self.Version)

		local Current, CurrentPrefix
		local Latest, LatestPrefix

		local Data = {
			UpdateLogs = self.Logs,
		}

		for i, SupportedVersion in ipairs(Supported) do
			Current, CurrentPrefix = GetVersionNumber(Version)
			Latest, LatestPrefix = GetVersionNumber(SupportedVersion)
			
			LatestPrefix = LatestPrefix or ""
			CurrentPrefix = CurrentPrefix or ""
			
			local LatestIndex = table.find(self.Prefixes, LatestPrefix)
			local CurrentIndex = table.find(self.Prefixes, CurrentPrefix)

			local Outdated = false
			local Valid = not (Current > Latest)
			
			if LatestIndex and CurrentIndex and LatestIndex < CurrentIndex then
				Outdated = true
			end
			
			if not LatestIndex or (LatestIndex and CurrentIndex and CurrentIndex < LatestIndex) then
				Valid = false
			end
			
			Data = {
				Outdated = Outdated or Latest > Current, --or CurrentPrefix ~= LatestPrefix,
				Valid = Valid,

				Latest = self.Version,
				Given = Version,
				Internals = self.Internals
			}

			if not Data.Outdated and Data.Valid then
				break
			end
		end

		return Data
	end,
}