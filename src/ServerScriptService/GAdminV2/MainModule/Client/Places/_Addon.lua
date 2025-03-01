--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Popup = require(Main.Shared.Services.Popup)
local Time = require(Main.Shared.Services.Core.Time)
local Configuration = require(Main.Settings.Interface)
--==

local Place = {}
Place.Name = "_Addon"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Addon = Arguments.Addon
	UI.MainFrame.Top.Title.Text = Arguments.Addon.Name--:sub(1, 10)
	
	Page.Author.Scrollable.Author.Text = Arguments.Addon.Author
	Page.Description.Scrollable.Description.Text = Arguments.Addon.Description or "N/A"
	Page.Version.Scrollable.Version.Text = Arguments.Addon.Version
	
	local Parameters = #Arguments.Addon.Parameters > 0 and `{table.concat(Arguments.Addon.Parameters, ", ")}.` or "[No Parameters]."
	Page.Parameters.Scrollable.Parameters.Text = `Modifies: {Parameters}`
	
	local Tag = Arguments.Addon.Tag
	Page.Tag.Visible = Tag ~= nil
	Page.Tag.Text = Tag or "N/A"
end

return Place