--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local UIService = require(Main.Client.Services.UI)
local Executor = require(Main.Client.Services.Framework.Executor)

local StringSnippets = require(Main.Shared.Services.Core.StringSnippets)
local Remote = require(Main.Shared.Services.Remote)
--==

local Place = {}
Place.Name = "_CodeEditor"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Submitting = false,
	Id = nil,
	
	Example = nil,
	Docs = nil,
	Submit = nil,
	CodeExecutor = nil,
	
	Holding = {
		Plus = nil,
		Minus = nil,
		Since = nil,
	}
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["1"]
	self.Arguments.CodeExecutor = Executor.new(Page)
	
	function self.Arguments.CodeExecutor:Run()
		return
	end
	
	-- Useless for now.	
	Page.Docs:Destroy()

	--Page.Docs.MouseEnter:Connnect(function()
	--	Sound:Play("Buttons", "Hover1")
	--end)
	
	--Page.Docs.Activated:Connect(function()
	--	Sound:Play("Buttons", "Click1")
	--	Interface:SetLocation()
	--end)
	
	Page.Save.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Save.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:Submit(Page, Interface, true)
	end)
	
	UserInputService.InputChanged:Connect(function(InputKey, GameProcessedEvent)
		if not Page.Visible or not self.Arguments.CodeExecutor.Focused or InputKey.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end

		local Up = InputKey.Position.Z > 0 
		local Down = InputKey.Position.Z <= 0

		self.Arguments.Holding.Plus = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Up
		self.Arguments.Holding.Minus = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Down

		local IsHolding = (self.Arguments.Holding.Plus or self.Arguments.Holding.Minus)
		self.Arguments.Holding.Since = IsHolding and tick() or self.Arguments.Holding.Since

		if IsHolding then
			self.Arguments.FirstTime = true
		end
	end)

	_G.GAdmin.Render(function()
		Page.List.Scrollable.Input_Resizer.TextSize = Page.List.Scrollable.Input.TextSize
		Page.TextSize.Text = `TextSize: {Page.List.Scrollable.Input.TextSize}`

		if not self.Arguments.Holding.Plus and not self.Arguments.Holding.Minus then
			return
		end

		local ToAdd = self.Arguments.Holding.Plus and 1 or -1
		if not self.Arguments.FirstTime then--if tick() - self.Arguments.Holding.Since < 1 and not self.Arguments.FirstTime then
			return
		end

		self.Arguments.FirstTime = false
		Page.List.Scrollable.Input.TextSize = math.clamp(Page.List.Scrollable.Input.TextSize + ToAdd, 8, 30)
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	if Page.Name ~= "1" then
		UI.MainFrame.Top.Title.Text = "Docs"
		return
	end
	
	UI.MainFrame.Top.Title.Text = "Code Editor"
	if not Arguments.Id then
		return
	end
	
	self.Arguments.Id = Arguments.Id
	self.Arguments.Example = Arguments.Example or "[CODE HERE]"
	self.Arguments.Docs = Arguments.Docs or "UNDEFINED"
	
	self.Arguments.Submit = Arguments.Submit or function(Id, String)
		local Success, Response = Remote:Fire("Code", "Save", Id, String)
		return {
			Success = Success,
			Response = Response,
		}
	end
	
	self:RefreshEditor(Frame, Page, Interface)
end

function Place:RefreshEditor(Frame, Page, Interface)
	Page.List.Scrollable.Input.PlaceholderText = self.Arguments.Example
	Page.List.Scrollable.Input.Text = ""
	self:RefreshDocs(Frame, Interface)
end

function Place:RefreshDocs(Frame, Interface)
	local Page = Frame.Pages["2"]
	local Strings = StringSnippets:Format(self.Arguments.Docs)
	local Labels = StringSnippets:ToLabel(Strings, GuiAssets.CodeEditorDocs, Page.Scrollable)
	StringSnippets:MoveLabel(Labels)
end

function Place:Submit(Page, Interface, Close)
	if not self.Arguments.Submit or self.Arguments.Submitting then
		return
	end
	
	self.Arguments.Submitting = true
	UIService:SetLoading(Interface.UI.MainFrame, function()
		return not self.Arguments.Submitting or not Page.Visible
	end)
	
	local Success, Request = pcall(function()
		return self.Arguments.Submit(self.Arguments.Id, self.Arguments.CodeExecutor.Input)
	end)
	
	if not Request then
		Interface.Popup:New({
			Type = "Error",
			Display = "Code Error",
			Text = "Submit callback haven't returned request value."
		})
		
		return
	end
	
	self.Arguments.Submitting = false
	if not Success or not Request.Success then
		Interface.Popup:New({
			Type = "Error",
			Display = "Code Error",
			Text = Success and (Request.Response or "Code failed.") or Request
		})
		
		return
	end
	
	if not Close then
		return
	end
	
	Interface:SetLocation(Interface.Location.Previous.Place, Interface.Location.Previous.Page)
	Interface.Popup:New({
		Type = "Notice",
		Display = "Code Saved",
		Text = "Code successfuly saved."
	})
end

return Place