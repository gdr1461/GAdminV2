--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
--==

local Command = {}
Command.Order = 12

Command.Name = "Fly"
Command.Alias = {}
Command.Description = "Makes player fly."

Command.Rank = 2
Command.Fluid = true

Command.Arguments = {
	{
		Name = "Player",
		Types = {"Player"},
		Rank = 3,

		Flags = {"Optional", "PlayerOnline", "PlayerClient"},
		Specifics = {},
	}
}

Command.Server = {}
Command.Client = {}

--== << Client >>
function Command.Client:Run(Caller, Arguments)
	self.Window = self.Window or require(Main.Client.Services.Framework.Window)
	local PreviousWindow = self.Window.Find("Default", "Fly") or self.Window.Find("Default", "Noclip")
	
	if PreviousWindow then
		PreviousWindow:Destroy()
	end
	
	local player = Arguments[1] or Caller
	self.Fly:Enable(player, "Fly")
	
	local Window = self.Window.new("Default")
	Window:SetTitle("Fly")
	
	Window.Destroying:Connect(function()
		self.Fly:Disable(player)
		self.Bind(player, "Fly", nil)
	end)
	
	Window:AddInputs({
		{
			Type = "Boolean",
			Title = "Enabled",
			
			State = true,
			Default = true,
			
			Key = {
				Key = Enum.KeyCode.E,
				Activated = function(Input)
					Input.SetState(not Input.State)
				end,
			},
			
			Activated = function(Input)
				if not Input.State then
					self.Fly:Disable(player)
					return
				end
				
				self.Fly:Enable(player, "Fly")
			end,
		},
		
		{
			Type = "Text",
			Title = "Speed",
			
			State = 50,
			Default = 50,
			
			Activated = function(Input)
				local Value = tonumber(Input.State)
				if not Value then
					return
				end
				
				self.Fly:SetSpeed(player, "Fly", Value)
			end,
		}
	})
	
	self.Bind(player, "Fly", function()
		if not Window:FindInput(1).State then
			return
		end
		
		self.Fly:Enable(player, "Fly")
	end)
end

function Command.Client:Get(Services)
	return {
		Bind = Services.Core.CharacterBind,
		Fly = Services.Core.Fly
	}
end

return Command