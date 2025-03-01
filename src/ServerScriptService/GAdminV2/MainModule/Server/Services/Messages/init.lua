--== << Services >>
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = script:FindFirstAncestor("Server")
local Main = ReplicatedStorage.GAdminShared

local Settings = require(Main.Settings.Main)
local PlayerService = require(Server.Services.Player)

local Remote = require(Main.Shared.Services.Remote)
local RemoteTable = require(script.Remotes)
--==

local Proxy = newproxy(true)
local Messages = getmetatable(Proxy)

Messages.__type = "GAdmin Messages"
Messages.__metatable = "[GAdmin Messages]: Metatable methods are restricted."
Messages.Calls = {}

function Messages:__tostring()
	return self.__type
end

function Messages:__index(Key)
	return Messages[Key]
end

function Messages:Load()
	task.spawn(function()
		for RemoteName, Callback in pairs(RemoteTable) do
			Remote:Connect(RemoteName, function(player, ...)
				if not PlayerService.Players[player.UserId] then
					repeat 
						task.wait()
					until PlayerService.Players[player.UserId]
				end
				
				self.Calls[player.UserId] = self.Calls[player.UserId] or 0

				if self.Calls[player.UserId] >= Settings.EventCalls then
					warn(`[{self.__type}]: {RemoteName} :: Player {player.Name} ({player.UserId}) is spamming requests.`)
					return
				end

				self.Calls[player.UserId] += 1
				local Index = #PlayerService.Players[player.UserId].Session.Requests
				
				PlayerService.Players[player.UserId].Session.Requests[Index] = self.Calls[player.UserId]
				return Callback(player, ...)
			end)
		end
		
		while task.wait(60) do
			for UserId, Calls in pairs(self.Calls) do
				if not PlayerService.Players[UserId] then
					self.Calls[UserId] = nil
					continue
				end
				
				table.insert(PlayerService.Players[UserId].Session.CommandUsage, 0)
				table.insert(PlayerService.Players[UserId].Session.Requests, 0)
				self.Calls[UserId] = 0
			end
		end
	end)
end

return Proxy