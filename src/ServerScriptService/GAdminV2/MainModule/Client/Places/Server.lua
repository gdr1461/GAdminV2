--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)
--==

local Place = {}
Place.Name = "Server"

Place.Previous = {
	Place = "Main",
	Page = 1
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	for i, Frame in ipairs(Frame.Pages["1"]:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame.Interact.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)
		
		Frame.Interact.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			Interface:SetLocation(Frame.Name)
		end)
		
		Interface:ConfigBlock(Frame.Interact, "Server", Frame.Name)
	end
end

return Place