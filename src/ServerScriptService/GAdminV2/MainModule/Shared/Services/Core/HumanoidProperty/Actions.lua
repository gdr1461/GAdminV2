return {
	{
		Name = "Set",
		Types = {"number", "string"},
		
		Handle = function(Property, Value)
			return Value
		end,
	},
	
	{
		Name = "Add",
		Types = {"number"},

		Handle = function(Property, Value)
			return Property + Value
		end,
	},
	
	{
		Name = "Remove",
		Types = {"number"},

		Handle = function(Property, Value)
			return Property - Value
		end,
	},
	
	{
		Name = "Divide",
		Types = {"number"},

		Handle = function(Property, Value)
			return Property / Value
		end,
	},
	
	{
		Name = "Multiply",
		Types = {"number"},

		Handle = function(Property, Value)
			return Property * Value
		end,
	},
	
	{
		Name = "Percent",
		Types = {"Limited"},

		Handle = function(Property, Value)
			return Property * Value / 100, true
		end,
	},
}