return {
	Enabled = true,
	Author = "@gdr1461account2",
	Version = "v1.0.0",
	
	Name = "Test Addon",
	Description = "GAdmin addon.",	
	Tag = "EXAMPLE",
	
	Parameters = {
		Commands = "@this.Assets.Commands",
		Ranks = "@this.Assets.Ranks",
		UI = "@this.Assets.UI",
		__Test = "Workspace.Value",
		ISettings = "@this.Assets.ISettings",
		--Settings = "@this.Assets.Settings",
	}
}