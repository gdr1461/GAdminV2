return {

	--[[
	
		Main settings of GAdmin v2 Interface.
		
	]]

	ShowTitle = false, --== Makes GAdmin title appear whenever topbar icon gets howered on.
	
	OpenAnimation = { --== Open and close animation of GAdmin Panel.
		Enabled = false,
		Configuration = {
			Time = .05, --== How long will animation play for.
			Style = Enum.EasingStyle.Sine, --== Tween Style of animation.
			Direction = Enum.EasingDirection.InOut, --== Tween Direction of animation.
		}
	},
	
	ShowPopups = true, --== Will show popups if any to an user.
	
	ShowBroadcasts = true, --== Will show broadcasts if any to an user.
	
	ThemeUsage = {
		--[[
			Describes what UI Theme setting could change it the panel color. (HSV)
		]]
		
		Hue = true, --== Will make UI Theme setting change hue of the panel.
		
		Saturation = true, --== Will make UI Theme setting change saturation of the panel.
		
		Value = false --== Will make UI Theme setting change value of the panel.
	},
	
	MainOnOpen = true, --== Makes GAdmin panel go to the Main frame.
	
	RankRefresh = 60, --== Time before Rank page will be reloaded.
	
	ExecutorThreadsRefresh = 60, --== Time before Threads in the Executor page will be reloaded.
	
	ServerRankRefresh = 60, --== Time before Server Rank page will be reloaded.
	
	BlockRefresh = 10, --== Time before rank name in blocked button will be reloaded.
	
	BanlistRefresh = 60, --== Time before banlist frame will be reloaded.
	
	StatsRefresh = 120, --== Time before whole Statistics location will be reloaded.
	
	LogRefresh = 60, --== Time before Logs page will be reloaded.
	
	PopupHistoryRefresh = 30, --== Time before Popup history page will be reloaded.
	
	CodeLimit = 0, --== How much of code per thread can be displayed in Executor page. (Set 0 for all.)
	
	ThreadLimit = 25, --== How much threads can be displayed in Executor page.

}