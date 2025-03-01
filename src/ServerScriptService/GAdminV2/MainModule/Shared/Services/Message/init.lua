--== << Services >>
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Main = script:FindFirstAncestor("GAdminShared")
local Remote = require(Main.Shared.Services.Remote)

local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui

local Sound = require(Main.Shared.Services.Sound)
local Settings = require(Main.Settings.Interface)

local Display = player and require(Main.Client.Services.Framework.Display) or nil
local TypesTable = require(script.Types)

local TweenInformation1 = TweenInfo.new(.7, Enum.EasingStyle.Exponential)
local TweenInformation2 = TweenInfo.new(.7, Enum.EasingStyle.Cubic)
--==

local Proxy = newproxy(true)
local Message = getmetatable(Proxy)

Message.__type = "GAdmin Message"
Message.__metatable = "[GAdmin Message]: Metatable methods are restricted."

Message.Queue = {}
Message.Current = 0
Message.Ids = 0

function Message:__tostring()
	return self.__type
end

function Message:__index(Key)
	return Message[Key]
end

function Message:New(Data)
	if not Settings.ShowBroadcast then
		return
	end
	
	if IsServer then
		Remote:Fire("SysMessage", Data.Player, Data)
		return
	end
	
	Data.Type = Data.Type or "Top"
	Data.Time = Data.Time or 10
	
	if not table.find({"Top", "Center"}, Data.Type) then
		warn(`[{self.__type}]: Message type '{Data.Type}' is invalid.`)
		return
	end
	
	Data.From = Data.From or "Server"
	Data.Message = Data.Message or "N/A"
	
	Data.OnEnd = Data.OnEnd or function(Frame, Options)

	end
	
	Message.Ids += 1
	local Id = Message.Ids
	
	table.insert(self.Queue, {
		Id = Id,
		Data = Data
	})
	
	self:Next()
end

function Message:Next()
	if self.Current ~= 0 or #self.Queue <= 0 then
		return
	end
	
	local Info = table.remove(self.Queue, 1)
	self.Current = Info.Id
	
	local Gui = player.PlayerGui.GAMessage
	local Frame = Gui[Info.Data.Type]
	
	Frame.Decoration.Size = Info.Data.SkipTween and UDim2.fromScale(0, 1) or UDim2.fromScale(1, 1)
	Frame.Size = (self.SkipTween or Info.Data.SkipTween) and UDim2.fromScale(1, .1) or UDim2.fromScale(0, .1)
	
	Frame.Position = TypesTable[Info.Data.Type].Position.Start
	Frame.AnchorPoint = TypesTable[Info.Data.Type].AnchorPoint.Start
	
	Frame.Visible = true
	if not self.SkipTween and not Info.Data.SkipTween then
		local Tween1 = TweenService:Create(Frame, TweenInformation1, {Size = UDim2.fromScale(1, .1)})
		Tween1:Play()
		Tween1.Completed:Wait()
	end
	
	Frame.Title.Text = `From {Info.Data.From}`
	Frame.Message.Text = Info.Data.Message
	
	if not Info.Data.SkipTween then
		local Tween2 = TweenService:Create(Frame.Decoration, TweenInformation1, {Size = UDim2.fromScale(0, 1)})
		Tween2:Play()
		Tween2.Completed:Wait()
	end
	
	self.SkipTween = #self.Queue > 0
	task.delay(Info.Data.Time, function()
		Frame.Position = TypesTable[Info.Data.Type].Position.End
		Frame.AnchorPoint = TypesTable[Info.Data.Type].AnchorPoint.End
		
		if not self.SkipTween then
			local Tween1 = TweenService:Create(Frame.Decoration, TweenInformation2, {Size = UDim2.fromScale(1, 1)})
			Tween1:Play()
			Tween1.Completed:Wait()
		end
		
		if not self.SkipTween then
			local Tween2 = TweenService:Create(Frame, TweenInformation2, {Size = UDim2.fromScale(0, .1)})
			Tween2:Play()
			Tween2.Completed:Wait()
		end
		
		Frame.Visible = false
		self.Current = 0
		
		Info.Data.OnEnd(Info)
		self:Next()
	end)
end

if not IsServer then
	Remote:Connect("SysMessage", function(...)
		Message:New(...)
	end)
end

return Proxy