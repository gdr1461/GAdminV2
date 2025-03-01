--[[

	For the addon to function correctly, it must be placed in a location where the client can replicate it, such as Workspace or ReplicatedStorage.

	When the addon starts, the following variables will be added to the Main module:

	Main.Client.Assets / Main.Server.Assets – The addon’s assets folder.
	
	Main.Client.Shared / Main.Server.Shared – A shared folder accessible by both the server and client. (Path: GAdminV2.MainModule.Shared)
	
	Main.Server.Server – A folder exclusive to the server. (Path: GAdminV2.MainModule.Server)
	
	Main.Client.Client – A folder exclusive to the client. (Path: GAdminV2.MainModule.Client)
]]

local Main = {}
Main.Server = {}
Main.Client = {}

function Main.Server:Start()
	
end

function Main.Client:Start()
	local Interface = require(self.Client.Services.Framework.Interface)
	Interface.Popup:New({
		Display = "Addon loaded",
		Type = "Notice",
		
		Text = "Addon by @gdr1461account2 has been loaded into the game.",
		Time = 20,
	})
end

return Main