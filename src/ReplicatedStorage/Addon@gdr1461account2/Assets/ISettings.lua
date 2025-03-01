local Settings = {}
Settings.Server = {}
Settings.Client = {}

function Settings.Server:Load(Config)
	Config:Set("TestSetting", true)
end

function Settings.Client:Load(Config)
	Config:Set({
		Name = "TestSetting",
		Description = "Test setting from the addon.",
		
		Type = "Boolean",
		Default = true,
		
		Callback = function(...)
			print(...)
		end,
	})
end

return Settings