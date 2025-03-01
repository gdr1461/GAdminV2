return {
	
	--[[
	
		Individual settings for each player. (Settings button in the panel.)
		
	]]
	
	LoadDelay = 0, -- Waiting N seconds before loading the panel.
	UISize = 1, -- Size of the panel.
	UISmoothness = .8, -- Smoothness of panel mouse dragging.
	
	UITheme = {
		Enabled = false, -- Will use specified color theme.
		Color = Color3.new(0.0431373, 0.0745098, 0.168627):ToHex() -- Specified color theme.
	},
	
	Sounds = {
		Buttons = .5, -- How loud will panel button sounds will be.
		Popups = .5 -- How loud will panel notice sounds will be.
	},
}