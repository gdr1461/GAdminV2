--== << Services >>
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local Main = script:FindFirstAncestor("GAdminShared")
local UIService = require(Main.Client.Services.UI)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local Remote = require(Main.Shared.Services.Remote)
local Cache = require(Main.Client.Services.Framework.Cache)

local Highlight = require(script.Highlighter)
local Indentation = require(script.Indentation)
--==

local Executor = {}
Executor.__index = Executor
Executor.__type = "GAdmin Executor"
Executor.Page = UIService.Gui.MainFrame.Places.Executor.Pages["1"]

function Executor:__tostring()
	return self.__type
end

function Executor:Load()
	self.Page.List.Scrollable.Input.Focused:Connect(function()
		self.Focused = true
	end)

	self.Page.List.Scrollable.Input.FocusLost:Connect(function(EnterPressed)
		self.Focused = false

		if EnterPressed then
			local DefaultText: string = self.Page.List.Scrollable.Input.Text
			local Text = {
				Previous = DefaultText:sub(1, self.Cursor - 1),
				Next = DefaultText:sub(self.Cursor, #DefaultText)
			}

			self.Page.List.Scrollable.Input.Text = `{Text.Previous}\n{Text.Next}`
			task.wait()

			self.Page.List.Scrollable.Input:CaptureFocus()
			--local FillAdded = self:UpdateFormat()
			
			--print(self.Page.List.Scrollable.Input.Text, self.Page.List.Scrollable.Input.Text:sub(self.Cursor + 1, #self.Page.List.Scrollable.Input.Text))
			--local Index = self.Page.List.Scrollable.Input.Text:gsub("\t", "    "):find("    ", self.Cursor + 1, true)
			--print(Index)
			self.Page.List.Scrollable.Input.CursorPosition = self.Cursor + 1 --+ (FillAdded[self.Line] or 0)--Index and Index + 4 or self.Cursor + 1
		end
	end)

	local Scrollable = self.Page.List.Scrollable
	Scrollable.Input:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		local Cursor = Scrollable.Input.CursorPosition
		if Cursor <= -1 then
			return
		end

		local Text = Scrollable.Input.Text:sub(1, Cursor + 1)
		local TextSize = TextService:GetTextSize(Text, Scrollable.Input.TextSize, Scrollable.Input.Font, Vector2.new(math.huge, math.huge))

		local CanvasX = TextSize.X - Scrollable.AbsoluteSize.X / 2
		local CanvasY = TextSize.Y - Scrollable.AbsoluteSize.Y / 2

		Scrollable.CanvasPosition = Vector2.new(math.max(0, CanvasX), math.max(0, CanvasY))
	end)

	_G.GAdmin.Render(function()
		self:Update()
	end)
end

function Executor:Run(Yield)
	self.Awaiting += 1
	local AwaitingId = self.Awaiting
	
	local Input = `local Args = \{...} local player, print, warn, Command = Args[1], Args[2], Args[3], Args[4] {self.Input}`
	local Success, Request = Remote:Fire("RunCode", "Run", Input, Yield)
	
	if not Success or not Request or AwaitingId ~= self.Awaiting then
		return
	end
	
	self.Job = Request.Job
	self.JobId = Request.JobId
	return Request
end

function Executor:Set(JobId, Input)
	local Job = Remote:Fire("RunCode", "GetJob", JobId)
	if not Job then
		return
	end

	self.Job = Job
	self.JobId = JobId or 1
	self.Input = Input or ""
end

function Executor:Clear()
	self.Page.List.Scrollable.Input.Text = ""
end

function Executor:UpdateLines()
	for i, Line in ipairs(self.Page.Lines.Scrollable:GetChildren()) do
		if not Line:IsA("TextLabel") or self.LineCount >= Line.LayoutOrder then
			continue
		end

		Line:Destroy()
	end

	for i = 1, self.LineCount do
		if self.Page.Lines.Scrollable:FindFirstChild(i) then
			continue
		end

		local Line = GuiAssets.Line:Clone()
		Line.Name = i
		Line.Text = i

		Line.LayoutOrder = i
		Line.Parent = self.Page.Lines.Scrollable
	end
end

function Executor:UpdateFormat()
	--== TODO
	
	local Formatted, FillAdded = Indentation:FillWords(self.Input:sub(1, self.Cursor))
	local String = Indentation:CloseBlocks(Formatted)
	--local Indented, Level = Indentation:Indent(String)

	self.Page.List.Scrollable.Input.Text = String--Indented
	return FillAdded
end

function Executor:Update()
	local Input = self.Page.List.Scrollable.Input.Text
	self.Input = Input

	local _, Count = Input:gsub("\n", "")
	Count += 1

	self.LineCount = Count
	self:UpdateLines()

	local Cursor = self.Page.List.Scrollable.Input.CursorPosition
	if Cursor > -1 then
		self.Cursor = Cursor
	end
	
	local Index = 0
	for Line in Input:sub(1, self.Cursor):gmatch("\n") do
		Index += 1
	end
	
	self.Line = Index + 1
	self.Page.List.Scrollable.Input_Resizer.TextSize = self.Page.List.Scrollable.Input.TextSize
	
	self.Page.Lines.Scrollable.UIGridLayout.CellSize = UDim2.new(1, 0, 0, self.Page.List.Scrollable.Input_Resizer.TextBounds.Y)
	self.Page.Lines.Scrollable.CanvasPosition = self.Page.List.Scrollable.CanvasPosition
end

return {
	new = function(Frame)
		local NewExecutor = setmetatable({}, Executor)
		NewExecutor.Focused = false

		NewExecutor.LineCount = 1
		NewExecutor.JobId = -1
		NewExecutor.Awaiting = 0
		NewExecutor.Cursor = -1
		NewExecutor.Line = 1
		NewExecutor.Page = Frame or NewExecutor.Page
		
		NewExecutor.Disconnect = Highlight.highlight({
			textObject = NewExecutor.Page.List.Scrollable.Input,
		})
		
		NewExecutor:Load()
		return NewExecutor
	end,
}