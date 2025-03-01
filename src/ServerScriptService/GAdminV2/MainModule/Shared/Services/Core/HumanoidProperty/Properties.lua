return {
	{
		Name = "Health",
		Alias = {"CurrentHP"},

		Types = {"number"},
		Handle = function(Humanoid, Get, Value)
			Humanoid.Health = Get(Humanoid.Health, Value)
			return Humanoid.Health
		end,
	},

	{
		Name = "MaxHealth",
		Alias = {"MaxHP"},

		Types = {"number"},
		Handle = function(Humanoid, Get, Value)
			Humanoid.MaxHealth = Get(Humanoid.MaxHealth, Value)
			return Humanoid.MaxHealth
		end,
	},

	{
		Name = "HP",
		Alias = {},

		Types = {"number", "Limited"},
		Handle = function(Humanoid, Get, Value)
			local FinalValue, ConstMax = Get(Humanoid.MaxHealth, Value)

			Humanoid.MaxHealth = ConstMax and Humanoid.MaxHealth or FinalValue
			Humanoid.Health = FinalValue

			return FinalValue
		end,
	},

	{
		Name = "WalkSpeed",
		Alias = {"Speed"},

		Types = {"number"},
		Handle = function(Humanoid, Get, Value)
			Humanoid.WalkSpeed = Get(Humanoid.WalkSpeed, Value)
			return Humanoid.WalkSpeed
		end,
	},

	{
		Name = "JumpPower",
		Alias = {"JumpHeight"},

		Types = {"number"},
		Handle = function(Humanoid, Get, Value)
			local Value = Get(Humanoid.JumpPower, Value)
			Humanoid.JumpHeight = Value
			Humanoid.JumpPower = math.sqrt(Value * workspace.Gravity * 2)
			return Value
		end,
	},

	{
		Name = "HealthDisplayDistance",
		Alias = {"HPDisplayDistance"},

		Types = {"number"},
		Handle = function(Humanoid, Get, Value)
			Humanoid.HealthDisplayDistance = Get(Humanoid.HealthDisplayDistance, Value)
			return Humanoid.HealthDisplayDistance
		end,
	},

	{
		Name = "NameDisplayDistance",
		Alias = {},

		Types = {"number"},
		Handle = function(Humanoid, Get, Value)
			Humanoid.NameDisplayDistance = Get(Humanoid.NameDisplayDistance, Value)
			return Humanoid.NameDisplayDistance
		end,
	}
}