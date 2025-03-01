--== << Services >>
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Main = script:FindFirstAncestor("GAdminShared")
local Shared = Main.Shared

local Rank = require(Shared.Services.Rank)
local Commands = require(Shared.Services.Commands)
local SearchConstructor = require(Main.Client.Services.Framework.Search)

local Sound = require(Shared.Services.Sound)
local Cache = require(Main.Client.Services.Framework.Cache)

local Assets = Shared.Assets
local GuiAssets = Assets.Gui
--==

local Place = {}
Place.Name = "Commands"
Place.Previous = {
	Place = "Main",
	Page = 1,
}

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	
}

function Place:Load(UI, Frame, Interface)
	self.Arguments.Search = SearchConstructor.new(Frame.Pages["1"].List)
	self.Arguments.Search:SetTemplate(Frame.Pages["1"].Search)
end

function Place:Reload(Page, Interface)
	self.Arguments.Search:Clear()
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") and not Frame:IsA("TextLabel") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Ranks = Rank:GetArray(Cache.Session.Rank, player.UserId)
	local List = Commands:GetRank(Ranks)
	
	local Items = {}
	for RankName, Commands in pairs(List) do
		local RankData = Rank:Find(RankName)
		if Cache.Session.Rank < RankData.Rank then
			continue
		end
		
		for i, Command in ipairs(Commands) do
			local Frame = GuiAssets.Command:Clone()
			Frame.Name = Command.Name
			
			Command.Description = Command.Description or "No description."
			local Arguments = ""
			
			for i, Argument in ipairs(Command.Arguments) do
				local Name = Argument.Name or Argument.Types[1]
				Arguments = `{Arguments} [{Name}]`
			end
			
			Frame.Title.Scrollable.Title.Text = `{Command.Name} <font color="#b3b3b3">{Arguments}</font>`
			Frame.Rank.Rank.Text = `{RankName}+`
			Frame.Description.Scrollable.Description.Text = Command.Description
			
			Frame.LayoutOrder = RankData.Rank * 1000 + i
			Frame.Parent = Page.List
			
			Frame.Interact.Activated:Once(function()
				Sound:Play("Buttons", "Click1")
				Interface:Refresh({
					Place = "_Command",
					Page = 1,
					MaxPages = 1,
					Arguments = {
						Command = Command,
					},
				})
			end)
			
			local SearchTable = table.clone(Command.Alias)
			local Search = {Command.Name, RankData.Rank, RankData.Name, Command.Description}
			
			for i, v in ipairs(Search) do
				table.insert(SearchTable, v)
			end
			
			table.insert(Items, {
				Frame = Frame.Name,
				Search = SearchTable
			})
		end
	end
	
	self.Arguments.Search.Items = Items
	self.Arguments.Search:Search(self.Arguments.Search.Current or "")
end

return Place