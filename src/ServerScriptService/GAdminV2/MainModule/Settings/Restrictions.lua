return {

	--[[
	
		Restrictions settings of GAdmin v2.
		@NOTE: Rank can be specified either as a name of rank, or place of a rank. (e.g. "User" or 0.)
		
	]]
	
	WelcomePopup = 1, -- Minimal rank for a welcome message to appear.
	ButtonAccess = 1, -- Minimal rank for the topbar button to appear.
	
	CmdBarAccess = 3, -- Access to the cmd bar interface.
	CommandCalls = 3, -- Removes command calls per minute restriction from user.
	
	APIBan = 4, -- Minimal rank to API ban someone from the game.

	Main = {
		--[[
		
			Access to the Main page buttons in the GAdmin Panel.
		
		]]
		
		About = 0,
		Commands = 0,
		Server = 0,
		Settings = 0
	},
	
	About = {
		--[[
		
			Access to the About page buttons in the GAdmin Panel.
		
		]]
		
		AddonAccess = 1, -- Access to addon list via in-game panel.
	},
	
	Server = {
		--[[
		
			Access to the Server page buttons in the GAdmin Panel.
		
		]]
		
		Statistics = 2,
		Ranks = 0,
		Executor = 4, -- WARNING: Anyone with access to the executor has access to anything in the game. Be careful with this permission.
		Editors = 3,
		Profile = 0
	},
	
	Ranks = {
		--[[
		
			Access to the Ranks page pages in the GAdmin Panel.
		
		]]
		
		ChangeRanks = 4, -- Access to rank manipulation via in-game panel.
		ChangeBanlistServer = 2, -- Access to server-wide banlist manipulation.
		ChangeBanlistGlobal = 3, -- Access to game-wide banlist manipulation.
		
		GlobalRankedUsers = 2, -- Access to see users that is hardcoded into having a rank in Rank Configuration.
		ServerRankedUsers = 2, -- Access to see user ranks on this server.
		Banlist = 2, -- Access to see banlist.
	},

}