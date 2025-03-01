--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Sound = require(Main.Shared.Services.Sound)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local Cache = require(Main.Client.Services.Framework.Cache)
local Remote = require(Main.Shared.Services.Remote)

local UIService = require(Main.Client.Services.UI)
local ArgumentFill = require(script.Argument)

--==

local Place = {}
Place.Name = "_CommandExecution"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Busy = false,
	Command = nil,
	Arguments = {}
}

function Place:Load(UI, Frame, Interface)
	Frame.Pages["1"].Execute.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Frame.Pages["1"].Execute.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.Busy or (self.Arguments.Debounce and tick() - self.Arguments.Debounce < 2) then
			return
		end
		
		self.Arguments.Busy = true
		UIService:SetLoading(UI.MainFrame, function()
			return not self.Arguments.Busy or not Frame.Pages["1"].Visible
		end, {
			OnEnd = function()
				Frame.Interactable = true
			end,
		})
		
		self.Arguments.Debounce = tick()
		local Message = self:GetMessage()
		
		if not Message then
			return
		end
		
		local Success = Remote:Fire("RunCommand", Message)
		self.Arguments.Busy = false
		
		if not Success then
			return
		end
		
		Interface.Popup:New({
			Type = "Notice",
			Text = "Command ran successfuly."
		})
	end)
end

function Place:Set(UI, Frame, Page, Arguments, Interface)
	self.Arguments.Command = Arguments.Command
	UI.MainFrame.Top.Title.Text = `Run Command`
	Page.Command.Scrollable.Command.Text = Arguments.Command.Name
	
	for i, Frame in ipairs(Page.Arguments.List:GetDescendants()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	ArgumentFill.Command = Arguments.Command
	for i, Argument in ipairs(Arguments.Command.Arguments) do
		local Name = Argument.Name or Argument.Types[1]
		local Template = GuiAssets.ExecutionArgument:Clone()
		
		Template.Name = `{i}-{Name}`
		Template.Title.Scrollable.Title.Text = Name
		
		local IsInfinite = table.find(Argument.Flags, "Infinite") or table.find(Argument.Types, "Object")
		Template.InputFrame.Input.Focused:Connect(function()
			ArgumentFill:Refresh(Template)
			ArgumentFill.Focused = true
			ArgumentFill.Index = i
		end)
		
		Template.InputFrame.Input.FocusLost:Connect(function()
			local Input = Template.InputFrame.Input.Text
			local InputNoSpaces = Input:gsub("%s+", "")
			
			local EmptyInput = InputNoSpaces == ""
			Input = not EmptyInput and Input or nil
			
			if not EmptyInput and Input ~= InputNoSpaces and not IsInfinite then
				Input = InputNoSpaces
				Template.InputFrame.Input.Text = InputNoSpaces
			end
			
			self.Arguments.Arguments[i] = Input
		end)
		
		Template.LayoutOrder = i
		Template.Parent = Page.Arguments.List
	end
end

function Place:GetMessage()
	if not self.Arguments.Command then
		return
	end
	
	local Message = `{Cache.Session.Prefix}{self.Arguments.Command.Name} {table.concat(self.Arguments.Arguments, " ")}`
	return Message
end

return Place