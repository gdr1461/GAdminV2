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
Place.Name = "Main"
Place.Previous = nil

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Buttons = {"About", "Commands", "Server", "Settings"},
	Pages = {
		["1"] = function(self, Page, Interface)
			self:RefreshButtons(Page, Interface)
		end,
	}
}

function Place:Load(UI, Frame, Interface)
	local Page = Frame.Pages["2"]
	_G.GAdmin.Scheduler:Insert("Global", "PopupHistoryRefresh", function()
		self.Arguments.DebounceHistory = tick()
		self:RefreshHistory(Page, Interface)
	end, Configuration.PopupHistoryRefresh)
	
	Page.Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceHistory and tick() - self.Arguments.DebounceHistory < 2 then
			return
		end
		
		self.Arguments.DebounceHistory = tick()
		self:RefreshHistory(Page, Interface)
	end)
end

function Place:Reload(Page, Interface)
	if not self.Arguments.Pages[Page.Name] then
		return
	end
	
	self.Arguments.Pages[Page.Name](self, Page, Interface)
end

function Place:RefreshButtons(Page, Interface)
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("TextButton") then
			continue
		end

		Frame:Destroy()
	end

	for Index, Name in ipairs(self.Arguments.Buttons) do
		local Frame = GuiAssets.MainButton:Clone()
		Frame.Name = Name
		Frame.Text = Name

		Frame.LayoutOrder = Index
		Frame.Parent = Page.List

		Frame.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)

		Frame.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			Interface:SetLocation(Name)
		end)

		Interface:ConfigBlock(Frame, "Main", Name)
	end
end

function Place:RefreshHistory(Page, Interface)
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end

	for i, Log in ipairs(Popup.History) do
		local Timestamp = Time:GetTime(Log.Time)
		local Time = Time:Format(Timestamp, {
			Divider = " ",
			Units = {
				{
					Unit = "Minute",
					Format = "%sm"
				},

				{
					Unit = "Second",
					Format = "%ss"
				},
			}
		})

		local IsInteractable = Log.Interaction ~= nil
		local Template = GuiAssets.PopupLog:Clone()

		Template.Name = `{i}-{Log.Type}`
		Template.Top.Type.Text = Log.Type

		Template.Top.Title.Text = Log.Title
		Template.Top.Time.Text = Time

		Template.Top.NotInteractable.Visible = not IsInteractable
		Template.Top.Interact.Visible = IsInteractable

		if IsInteractable then
			Template.Top.Interact.MouseEnter:Connect(function()
				Sound:Play("Buttons", "Hover1")
			end)

			Template.Top.Interact.Activated:Connect(function()
				Sound:Play("Buttons", "Click1")
				Log.Interaction()
			end)
		end

		Template.LayoutOrder = -i
		Template.Parent = Page.List
		Template.Scrollable.Content.Text = Log.Text
	end
end

return Place