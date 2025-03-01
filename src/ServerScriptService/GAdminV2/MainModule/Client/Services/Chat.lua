--== << Services >>
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local PlayerGui = player.PlayerGui
local Gui

local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local GuiAssets = Assets.Gui
local ChatAssets = GuiAssets.Chat

local Sound = require(Main.Shared.Services.Sound)
local Remote = require(Main.Shared.Services.Remote)
--==

local Chat = {}
Chat.Chats = {}
Chat.Input = ""

Chat.Length = 0
Chat.Current = 0

function Chat:Load()
	Gui = PlayerGui:WaitForChild("GAMessage")
	local Draggable = _G.GAdmin.Framework:Display("Draggable", Gui.Chat)
	
	Draggable:Enable()
	self.Draggable = Draggable
	
	Remote:Connect("Chat", function(Action, Data)
		if Action == "SetMessages" then
			local UserId = Data[1]
			local RawMessages = Data[2]
			
			local Messages = {}
			for i, Message in ipairs(RawMessages) do
				local Data = {
					Author = Message.Author == player.UserId and "Self" or "Other",
					Message = Message.Message
				}
				
				table.insert(Messages, Data)
			end
			
			self.Chats[UserId] = self.Chats[UserId] or self:CreateChat(UserId)
			self.Chats[UserId].Messages = Messages
			self:Update()
			return
		end
		
		if not self[Action] then
			return
		end
		
		self[Action](self, unpack(Data))
	end)
	
	Players.PlayerRemoving:Connect(function(PlayerRemoving)
		if not self.Chats[PlayerRemoving.UserId] then
			return
		end
		
		self.Chats[PlayerRemoving.UserId] = nil
		self:Update()
		
		if self.Current ~= PlayerRemoving.UserId then
			return
		end
		
		self:SetChat(0)
	end)
	
	Gui.Chat.Send.SendFrame.Interact.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Gui.Chat.Send.SendFrame.Interact.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:SendMessage(self.Input)
	end)
	
	Gui.Chat.Top.Close.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
	end)
	
	Gui.Chat.Top.Close.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:SetVisible(false)
	end)
	
	Gui.Chat.Send.InputFrame.Input.FocusLost:Connect(function(EnterPressed)
		if not EnterPressed then
			return
		end
		
		self:SendMessage(self.Input)
	end)
	
	Gui.Chat.Send.InputFrame.Input:GetPropertyChangedSignal("Text"):Connect(function()
		self.Input = Gui.Chat.Send.InputFrame.Input.Text
	end)
end

function Chat:SetVisible(State)
	if State == nil then
		State = not Gui.Chat.Visible
	end
	
	Gui.Chat.Visible = State
end

function Chat:Update()
	if not self:IsValid() then
		return self:SetChat(0)
	end
	
	self:UpdateChats()
	self:UpdateChat()
end

function Chat:UpdateChat()
	if not self.Chats[self.Current] or not self:IsValid() then
		return
	end
	
	self:SetMessages(self.Chats[self.Current].Messages)
end

function Chat:UpdateChats()
	for i, Frame in ipairs(Gui.Chat.Top.Chats:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	for UserId, Chat in pairs(self.Chats) do
		local Chatter = self:GetChatter(UserId)
		if not Chatter then
			continue
		end
		
		local Avatar = self:GetAvatar(UserId)
		local Template = ChatAssets.Chat:Clone()
		
		Template.Name = UserId
		Template.Scrollable.Username.Text = Chatter.Name
		
		Template.Avatar.Image = Avatar or ""
		Template.Avatar.Error.Visible = not Avatar
		
		Template.Interact.BackgroundColor3 = UserId == self.Current and Color3.new(0.129412, 0.172549, 0.298039) or Color3.new(0.180392, 0.239216, 0.419608)
		Template.Interact.Interactable = UserId ~= self.Current
		
		Template.Interact.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			self:SetChat(UserId)
		end)
		
		Template.LayoutOrder = UserId == self.Current and -1 or Chat.Id
		Template.Parent = Gui.Chat.Top.Chats
	end
end

function Chat:IsValid()
	return self.Current == 0 or self:GetChatter() ~= nil
end

function Chat:GetChatter(UserId)
	local Success, Chatter = pcall(function()
		return Players:GetPlayerByUserId(UserId or self.Current)
	end)
	
	if not Success then
		return
	end
	
	return Chatter
end

function Chat:GetAvatar(UserId)
	if self.Chats[UserId] and self.Chats[UserId].Avatar then
		return self.Chats[UserId].Avatar
	end
	
	local Success, Image = pcall(function()
		return Players:GetUserThumbnailAsync(UserId or self.Current, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	
	if not Success then
		return
	end
	
	if self.Chats[UserId] then
		self.Chats[UserId].Avatar = Image
	end
	
	return Image
end

function Chat:GetContainerType(Side, Index)
	Index = Index or #self.Chats[self.Current].Messages + 1
	local LastMessage
	
	for i, Message in ipairs(self.Chats[self.Current].Messages) do
		if i >= Index then
			break
		end
		
		LastMessage = Message
	end
	
	if not LastMessage or LastMessage.Author ~= Side or LastMessage.Type == "Default" then
		return "Avatar"
	end
	
	return "Default"
end

function Chat:GetContainer(Side, Type)
	local SideFrame = ChatAssets.Types:FindFirstChild(Side)
	if not SideFrame then
		warn(`[GAdmin Chat]: Side '{Side}' is not valid.`)
		return
	end
	
	local TypeFrame = SideFrame:FindFirstChild(Type)
	if not TypeFrame then
		warn(`[GAdmin Chat]: Type '{Type}' is not valid.`)
		return
	end
	
	local Container = ChatAssets.Container:Clone()
	local Frame = TypeFrame:Clone()
	
	Frame.Name = "Holder"
	Frame.Parent = Container
	
	Container:SetAttribute("Type", Type)
	return Container
end

function Chat:SetContainer(Container, Context)
	local Type = Container:GetAttribute("Type")
	if Type == "Avatar" and Container:FindFirstChild("Holder") then
		local Avatar = self:GetAvatar()
		Container.Holder.Avatar.Image = Avatar or ""
		Container.Holder.Avatar.Error.Visible = Avatar == nil
	end
	
	Container.Name = `{Context.Author}-Container`
	Container.Holder.MessageFrame.Scrollable.Message.Text = Context.Message
	Container.Parent = Gui.Chat.Current
	
	return Container
end

function Chat:SendMessage(Message)
	if self.Input:gsub("%s+", "") == "" then
		return
	end
	
	Gui.Chat.Send.InputFrame.Input.Text = ""
	Remote:Fire("Chat", "Send", self.Current, Message)
end

function Chat:Send(Context)
	local Type = self:GetContainerType(Context.Author)
	local Container = self:GetContainer(Context.Author, Type)
	
	self:SetContainer(Container, Context)
	table.insert(self.Chats[self.Current].Messages, Context.Message)
end

function Chat:SetMessages(Messages)
	for i, Frame in ipairs(Gui.Chat.Current:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end
	
	for i, Context in ipairs(Messages) do
		local Type = self:GetContainerType(Context.Author, i)
		local Container = self:GetContainer(Context.Author, Type)
		self:SetContainer(Container, Context)
	end
end

function Chat:EmptyChat()
	self.Current = 0
	for i, Frame in ipairs(Gui.Chat.Current:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end
	
	self:Update()
end

function Chat:CreateChat(UserId)
	if UserId == 0 then
		self:EmptyChat()
		return
	end
	
	self.Length += 1
	local Chat = {
		Messages = {},
		Id = self.Length,
	}
	
	return Chat
end

function Chat:SetChatUnreliable(UserId)
	if self.Current ~= 0 then
		self.Chats[UserId] = self.Chats[UserId] or self:CreateChat(UserId)
		return
	end
	
	self:SetChat(UserId)
end

function Chat:SetChat(UserId)
	if UserId == 0 then
		self:EmptyChat()
		return
	end
	
	local Chatter = self:GetChatter(UserId)
	if not Chatter then
		return
	end
	
	self.Current = UserId
	self.Chats[UserId] = self.Chats[UserId] or self:CreateChat(UserId)
	
	self:GetAvatar(UserId)
	self:Update()
	
	self:SetVisible(true)
	return self.Chats[UserId]
end

return Chat