local Cache = {}

Cache.Prefixes = {
	INDEV = {
		Color = Color3.new(0.564706, 0.831373, 1):ToHex(),
		Description = "GAdmin is currently under development, which means a lot of features are missing."
	},
	
	ALPHA = {
		Color = Color3.new(0.333333, 0.635294, 1):ToHex(),
		Description = "Early product that only specific people have access to."
	},
	
	BETA = {
		Color = Color3.new(0.172549, 0.545098, 1):ToHex(),
		Description = "Stage of development on which new features are tested on."
	},
	
	RELEASE = {
		Color = Color3.new(0.423529, 0.576471, 1):ToHex(),
		Description = "Release version of admin panel, will dissappear after hot fixes."
	}
}

Cache.Banlist = {}

return Cache