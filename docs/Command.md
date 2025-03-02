---
sidebar_position: 7
---

# Command
Commands in GAdmin are pre-defined modules that execute when a chat command is used. <br/>
Example: `;fly me` triggers the Fly module command. <br/>

## Features
GAdmin chat commands offer a flexible API that can be customized to your needs. You can set the required rank to use a command, define flexible arguments with custom autocompletion, and support both `server` and `client` execution — all within a single module.

## Templates
:::info
For a better understanding of how arguments work, see [Command Arguments](/docs/Arguments).
:::

The standard structure of a GAdmin command follows a specific format:

```lua
local Command = {}
Command.Name: string -- Unique name of custom command.

Command.Alias: array -- Other names of your command. Needs to be unique too.
Command.Description: string -- Description of your command.

Command.Rank: string | number -- Rank required to use command.
Command.Fluid: boolean --[[ Will API be able to send updates to the client for this
commannd and will UpPeRcAsE matter when you call command in the chat. ]]

Command.Arguments: array -- Arguments that you may need for your own command.

Command.Server = {} -- Server side.
Command.Client = {} -- Client side.

--== << Server >>
-- Run command on the server.
function Command.Server:Run(Caller, Arguments)
	...
end

-- What services your command need on the server side.
function Command.Server:Get(Services)
	...
end

--== << Client >>
-- Run command on the client.
function Command.Client:Run(Caller, Arguments)
	...
end

-- What services your command need on the client side.
function Command.Client:Get(Services)
	...
end

return Command
```

Here's some examples of commands for you to reference: <br/>

### Bring
```lua
local Command = {}
Command.Name = "Bring"

Command.Alias = {"Br"}
Command.Description = "Teleports player to you."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,

		Flags = {"PlayerOnline"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1]
	local Position = Caller.Character:GetPivot() * CFrame.Angles(0, math.rad(180), 0)
	player.Character:PivotTo(Position)
end

return Command
```

### Shutdown
```lua
local Command = {}
Command.Name = "Shutdown"

Command.Alias = {}
Command.Description = "Shutdowns current server with specified reason if any."

Command.Rank = 4
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Reason",
		Types = {"string"},
		Rank = 3,
		
		Flags = {"Optional", "Infinite", "ToFilter"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local Reason = Arguments[1] or `By @{Caller.Name}`
	self.API:Shutdown(Reason)
end

function Command.Server:Get(Services)
	return {
		API = Services.API
	}
end

return Command
```

### ChatLogs
```lua
--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local HumanoidProperty = require(Main.Shared.Services.Core.HumanoidProperty)

local Properties = HumanoidProperty:GetList()
local Property = ""
--==

local Command = {}
Command.Name = "ChatLogs"

Command.Alias = {"CLogs"}
Command.Description = "Shows chat logs."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"Optional", "PlayerOnline", "PlayerClient"},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Client >>
function Command.Client:Run(Caller, Arguments)
	_G.GAdmin.Framework.Interface:Refresh({
		Place = "_Logs",
		Page = 1,
		MaxPages = 1,
		Arguments = {
			Type = "ChatLogs",
		},
	})
end

return Command
```

### Countdown
```lua
local Command = {}
Command.Name = "Countdown"

Command.Alias = {"Count", "CD"}
Command.Description = "Count downs time."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Time",
		Types = {"number"},
		Rank = 2,

		Flags = {},
		Specifics = {},
	},
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local Time = math.clamp(Arguments[1], 1, 99)
	for i = Time, 1, -1 do
		self.Remote:FireAll("SysMessage", {
			Type = "Center",
			From = `Server`,
			Message = i,
			Time = 1,
			SkipTween = i ~= Time,
		})
		
		task.wait()
	end
end

function Command.Server:Get(Services)
	return {
		Remote = Services.Remote
	}
end

return Command
```