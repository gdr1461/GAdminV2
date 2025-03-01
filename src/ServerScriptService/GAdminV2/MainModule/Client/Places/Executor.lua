--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local Sound = require(Main.Shared.Services.Sound)

local Cache = require(Main.Client.Services.Framework.Cache)
local Settings = require(Main.Settings.Interface)

local Remote = require(Main.Shared.Services.Remote)
local Highlighter = require(Main.Client.Services.Framework.Executor.Highlighter)

local UIService = require(Main.Client.Services.UI)
local Configuration = require(Main.Settings.Interface)
--==

local Place = {}
Place.Name = "Executor"
Place.Previous = function(Location)
	return Location.Previous
end

Place.Page = 0
Place.MaxPages = 0

Place.Arguments = {
	Holding = {
		Since = 0,
		FirstTime = false,
		
		Plus = false,
		Minus = false,
	},
	
	ThreadStatus = {
		dead = {
			Display = "Dead",
			Color = Color3.new(1, 0.388235, 0.388235)
		},
		
		normal = {
			Display = "Finished",
			Color = Color3.new(1, 1, 1)
		},
		
		running = {
			Display = "Running",
			Color = Color3.new(0.415686, 1, 0.501961)
		},
		
		suspended = {
			Display = "Suspended",
			Color = Color3.new(1, 0.952941, 0.447059)
		},
	},
	
	WasOnOtherPage = false,
	Pages = {
		["1"] = function(self, Page, Interface)
			if self.Arguments.WasOnOtherPage then
				self.Arguments.WasOnOtherPage = false
				return
			end
			
			Page.List.Scrollable.Input.Text = ""
			self:SetOutput(Page, {})
		end,
		
		["2"] = function(self, Page, Interface)
			self.Arguments.WasOnOtherPage = true
		end,
	}
}

function Place:Load(UI, Frame, Interface)
	_G.GAdmin.Scheduler:Insert("Global", "DebounceThreadsClient", function()
		self.Arguments.DebounceThreads = tick()
		self:RefreshThreads(UI, Frame, Interface)
	end, Settings.ExecutorThreadsRefresh)
	
	local Page = Frame.Pages["1"]
	Page.Run.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Page.Run.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:Run(Page)
	end)
	
	Frame.Pages["2"].Reload.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Frame.Pages["2"].Reload.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		if self.Arguments.DebounceThreads and tick() - self.Arguments.DebounceThreads < 2 then
			return
		end
		
		self.Arguments.DebounceThreads = tick()
		self:RefreshThreads(UI, Frame, Interface)
	end)
	
	UserInputService.InputChanged:Connect(function(InputKey, GameProcessedEvent)
		if not Page.Visible or not Cache.MainExecutor.Focused or InputKey.UserInputType ~= Enum.UserInputType.MouseWheel then
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
	
	Remote:Connect("RunCodeCallback", function(Action, ...)
		if Action == "RefreshThreads" then
			self:RefreshThreads(UI, Frame, Interface, ...)
			return
		end
		
		if Action == "SetOutput" then
			self:SetOutput(Page, ...)
			return
		end
	end)
end

function Place:Reload(Page, Interface)
	self.Arguments.Pages[Page.Name](self, Page, Interface)
end

function Place:Run(Page)
	local Request = Cache.MainExecutor:Run(true)
	if not Request or not Request.Response then
		return
	end
	
	self:SetOutput(Page, Request.Response)
end

function Place:SetOutput(Page, Outputs)
	for i, Label in ipairs(Page.Output.Scrollable:GetChildren()) do
		if not Label:IsA("TextLabel") then
			continue
		end
		
		Label:Destroy()
	end
	
	for i, Output in ipairs(Outputs) do
		local Label = GuiAssets.Output:Clone()
		Label.Name = i
		Label.Text = Output
		
		Label.LayoutOrder = i
		Label.Parent = Page.Output.Scrollable
	end
end

function Place:RefreshThreads(UI, Frame, Interface, GivenThreads)
	self.DebounceThreads = tick()
	local Page = Frame.Pages["2"]
	
	for i, Frame in ipairs(Page.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Success, RawThreads = true, GivenThreads
	if not RawThreads then
		Success, RawThreads = Remote:Fire("RunCode", "GetJobs")
	end
	
	Page.Error.Visible = false
	
	if not Success then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = RawThreads
		return
	end
	
	if #RawThreads <= 0 then
		Page.Error.Visible = true
		Page.Error.Scrollable.Error.Text = "No threads were found."
		return
	end
	
	local Threads = {}
	table.move(RawThreads, math.max(#RawThreads - Configuration.ThreadLimit, 1), #RawThreads, 1, Threads)
	
	for i, Thread in ipairs(Threads) do
		if not Thread.JobId then
			continue
		end
		
		local Code = Thread.Data:sub(91, #Thread.Data)
		local Status = self.Arguments.ThreadStatus[Thread.Status]
		local Frame = GuiAssets.Thread:Clone()
		
		Frame.Name = `Thread-{Thread.JobId}`
		Frame.JobId.Text = Thread.JobId
		
		Frame.Caller.Scrollable.Caller.Text = Thread.Caller
		Frame.Code.Scrollable.Code.Text = Configuration.CodeLimit ~= 0 and Code:sub(1, Configuration.CodeLimjt) or Code
		
		Frame.Status.Scrollable.Status.Text = Status.Display
		Frame.Status.Scrollable.Status.TextColor3 = Status.Color
		
		Frame.Cancel.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)

		Frame.Cancel.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			if self.Busy then
				return
			end

			self.Arguments.Busy = true
			UIService:SetLoading(UI.MainFrame, function()
				return not self.Arguments.Busy or not Page.Visible
			end)

			local Success = Remote:Fire("RunCode", "Cancel", Thread.Index)
			self.Arguments.Busy = false
		end)
		
		Frame.Recall.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
		end)
		
		Frame.Recall.Activated:Connect(function()
			Sound:Play("Buttons", "Click1")
			if self.Busy then
				return
			end
			
			self.Arguments.Busy = true
			UIService:SetLoading(UI.MainFrame, function()
				return not self.Arguments.Busy or not Page.Visible
			end)
			
			local Success = Remote:Fire("RunCode", "Recall", Thread.Index)
			self.Arguments.Busy = false
		end)
		
		Frame.LayoutOrder = -Thread.JobId
		Frame.Parent = Page.List
		
		Highlighter.highlight({
			textObject = Frame.Code.Scrollable.Code
		})
	end
end

return Place