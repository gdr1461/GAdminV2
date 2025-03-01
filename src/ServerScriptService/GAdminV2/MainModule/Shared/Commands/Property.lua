--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local HumanoidProperty = require(Main.Shared.Services.Core.HumanoidProperty)

local Properties = HumanoidProperty:GetList()
local Property = ""
--==

local Command = {}
Command.Order = 27

Command.Name = "Property"
Command.Alias = {"Prop", "Pr"}
Command.Description = "Changes property of specified player's character."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 2,

		Flags = {"Optional", "PlayerOnline"},
		Specifics = {},
	},
	
	{
		Name = "Property",
		Types = {"string"},
		Rank = 2,
		
		Flags = {},
		Specifics = {
			AutoFillOverride = true,
			AutoFill = {
				function(Command, Argument, Word)
					Property = Word
					return Properties
				end,
			}
		}
	},
	
	{
		Name = "Value",
		Types = {"number", "string"},
		Rank = 2,

		Flags = {},
		Specifics = {}
	},
	
	{
		Name = "Action",
		Types = {"string"},
		Rank = 2,
		
		Flags = {"Optional"},
		Specifics = {
			AutoFillOverride = true,
			AutoFill = {
				function(Command, Argument, Word)
					return HumanoidProperty:GetPropertyActions(Property)
				end,
			}
		}
	}
}

Command.Server = {}
Command.Client = {}

--== << Server >>
function Command.Server:Run(Caller, Arguments)
	local player = Arguments[1] or Caller
	local Property = Arguments[2]
	local Value = Arguments[3]
	local Action = Arguments[4] or "Set"
	
	local Success, Response = HumanoidProperty:Set(player.Character.Humanoid, Action, Property, Value)
	if not Success then
		self.Popup:New({
			Player = Caller,
			Type = "Error",
			Text = Response
		})
		
		return
	end
	
	self.Popup:New({
		Player = Caller,
		Type = "Notice",
		Text = `Property <font color="#ffbfaa">{Property}</font> has been successfully set to <font color="#ffbfaa">{Response}</font>.`
	})
end

function Command.Server:Get(Services)
	return {
		Popup = Services.Popup
	}
end

return Command