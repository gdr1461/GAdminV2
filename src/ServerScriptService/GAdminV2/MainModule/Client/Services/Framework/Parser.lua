--== << Services >>
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Main = script:FindFirstAncestor("GAdminShared")
local Remote = require(Main.Shared.Services.Remote)
--==

local Proxy = newproxy(true)
local Parser = getmetatable(Proxy)

Parser.__type = "GAdmin Framework Parser"
Parser.__metatable = "[GAdmin Framework Parser]: Metatable methods are restricted."

function Parser:__tostring()
	return self.__type
end

function Parser:__index(Key)
	return Parser[Key]
end

function Parser:Load()
	local Commands = require(Main.Shared.Services.Commands)
	Commands:Reload()
	
	Remote:Connect("RunCommandClient", function(CommandName, Arguments)
		local Command = Commands:Find(CommandName)
		if not Command then
			warn(`[{self.__type}]: Command with name '{CommandName}' is invalid.`)
			return
		end
		
		if not Command.Client or not Command.Client.Run then
			return
		end
		
		Command.Client:Run(player, Arguments)
	end)
	
	Remote:Connect("FluidCommand", function(CommandName, Arguments)
		local Command = Commands:Find(CommandName)
		if not Command then
			warn(`[{self.__type}]: Command with name '{CommandName}' is invalid.`)
			return
		end
		
		if not Command.Fluid then
			return
		end
		
		Command.Arguments = Arguments
	end)
end

return Proxy