--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)
--==

local Place = {}
Place.Name = "Statistics"
Place.Previous = {
	Place = "Server",
	Page = 1,
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	Page.Server.Interact.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Server.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		Interface:SetLocation("_ServerStats", 1)
	end)
	
	Page.Players.Interact.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)

	Page.Players.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		Interface:SetLocation("_PlayerStatsPicker", 1)
	end)
end

return Place