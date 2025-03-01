--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Shared = Main.Shared

local Sound = require(Shared.Services.Sound)
local Rank = require(Shared.Services.Rank)
local Cache = require(Main.Client.Services.Framework.Cache)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
--==

local Place = {}
Place.Name = "_Command"
Place.Previous = {
	Place = "Commands",
	Page = 1
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	Frame.Pages["1"].Rank.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		Interface:SetLocation("Ranks")
		
		local RankName = Rank:Find(self.Arguments.Command.Rank).Name
		Interface.Location.Frame.Pages["1"].Search.Input.Input.Text = RankName
		Interface.Location.Data.Arguments.Search:Search(RankName)
	end)
	
	Frame.Pages["1"].Arguments.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		local CommandRank = Rank:Find(self.Arguments.Command.Rank)
		if Cache.Session.Rank < CommandRank.Rank then
			Interface.Popup:New({
				Type = "Error",
				Text = `Rank '<font color="#">{CommandRank.Name}</font>+' required to run this command.`,
				Time = 20,
			})
			
			return
		end
		
		Interface:Refresh({
			Place = "_CommandExecution",
			Back = "Commands",
			
			Page = 1,
			MaxPages = 1,
			Arguments = {
				Command = self.Arguments.Command
			}
		})
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Command = Arguments.Command
	UI.MainFrame.Top.Title.Text = Arguments.Command.Name
	local CommandArguments = ""
	
	for i, Argument in ipairs(Arguments.Command.Arguments) do
		local Name = Argument.Name or Argument.Types[1]
		CommandArguments = `{CommandArguments} [{Name}]`
	end
	
	Page.Arguments.Scrollable.Arguments.Text = CommandArguments:gsub("%s", "") ~= "" and CommandArguments or "[None]"
	Page.Description.Scrollable.Description.Text = Arguments.Command.Description
	
	local RankData = Rank:Find(Arguments.Command.Rank)
	Page.Rank.Rank.Text = `{RankData.Name}+`
	
	local HasAlias = #Arguments.Command.Alias > 0
	local HasTag = Arguments.Command.Tag ~= nil
	
	Page.Tag.Visible = HasTag
	Page.Tag.Text = HasTag and Arguments.Command.Tag.Name or "N/A"
	Page.Tag.TextColor3 = HasTag and Arguments.Command.Tag.Color or Color3.new(1, 1, 1)
	
	Page.Description.Position = HasAlias and UDim2.new(.5, 0, .66, 0) or UDim2.new(.5, 0, .44, 0)
	Page.Description.Size = HasAlias and UDim2.new(.9, 0, .4, 0) or UDim2.new(.9, 0, .5, 0)
	
	Page.Alias.Visible = HasAlias
	Page.Alias.Scrollable.Alias.Text = `Alias: {table.concat(Arguments.Command.Alias, ", ")}`
end

return Place