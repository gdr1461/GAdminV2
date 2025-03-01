local Ranks = {

	--[[
	
		Default ranks of the GAdmin v2.
		
	]]

	{
		Name = "Owner",
		Rank = 5,
		Color = Color3.new(1, 0.741176, 0.223529):ToHex(),
		Players = {}
	},

	{
		Name = "Manager",
		Rank = 4,
		Color = Color3.new(0.133333, 0.521569, 1):ToHex(),
		Players = {}
	},

	{
		Name = "Admin",
		Rank = 3,
		Color = Color3.new(0.478431, 0.388235, 1):ToHex(),
		Players = {}
	},

	{
		Name = "Mod",
		Rank = 2,
		Color = Color3.new(0.972549, 1, 0.647059):ToHex(),
		Players = {}
	},

	{
		Name = "Privileged",
		Rank = 1,
		Color = Color3.new(0.968627, 1, 0.85098):ToHex(),
		Players = {}
	},

	{
		Name = "User",
		Rank = 0,
		Color = Color3.new(0.33333, 0.33333, 0.33333):ToHex(),
		Players = {},
		__Global = true,
	},

}

return {
	Ranks = Ranks,
}