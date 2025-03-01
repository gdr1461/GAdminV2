--== << Services >>
local Players = game:GetService("Players")
local Main = script:FindFirstAncestor("Server")

local Data = require(Main.Data)
local Remote = require(Data.Shared.Services.Remote)
local Filter = require(Data.Shared.Services.Core.Filter)
--==

local Chat = {}
Chat.Chats = {}

function Chat:GetChatter(UserId)
	local Success, Chatter = pcall(function()
		return Players:GetPlayerByUserId(UserId)
	end)
	
	if not Success then
		return
	end
	
	return Chatter
end

function Chat:GetChat(UserId, UserId2)
	for i, Chat in ipairs(self.Chats) do
		if not table.find(Chat.Users, UserId) or not table.find(Chat.Users, UserId2) then
			continue
		end
		
		return Chat, i
	end
	
	table.insert(self.Chats, {
		Users = {UserId, UserId2},
		Messages = {}
	})
	
	return self.Chats[#self.Chats], #self.Chats
end

function Chat:Send(player, UserId, Message)
	if UserId ~= UserId or type(UserId) ~= "number" then
		return
	end
	
	if type(Message) ~= "string" or not utf8.len(Message) then
		return
	end
	
	local Id = `{player.UserId}-{UserId}`
	local Chatter = self:GetChatter(UserId)
	
	if not Chatter then
		self.Chats[Id] = nil
		return
	end
	
	local Chat, Index = self:GetChat(player.UserId, UserId)
	local FilteredMessage = Filter:Filter(Message, player.UserId)
	
	table.insert(Chat.Messages, {
		Author = player.UserId,
		Message = FilteredMessage
	})
	
	Remote:Fire("Chat", player, "SetMessages", {UserId, Chat.Messages})
	if player.UserId == UserId then
		return
	end
	
	Remote:Fire("Chat", Chatter, "SetMessages", {player.UserId, Chat.Messages})
	Remote:Fire("Chat", Chatter, "SetChatUnreliable", {player.UserId})
end

return Chat