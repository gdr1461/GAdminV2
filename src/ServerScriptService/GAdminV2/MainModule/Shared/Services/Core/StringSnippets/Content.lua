--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Main = script:FindFirstAncestor("GAdminShared")
local Highlight = require(Main.Client.Services.Framework.Executor.Highlighter)
--==

return {
	{
		Type = "Normal",
		Snippet = nil,
		
		Redact = function(Snippet)
			Snippet.Label.Text = Snippet.Data
		end,
	},
	
	{
		Type = "Props",
		Snippet = "props",
		
		Attributes = {
			size = {
				Name = "Size",
				Type = function(Attribute)
					local Number = tonumber(Attribute)
					return {
						Success = Number ~= nil,
						Response = Number or `Unable to convert '{Attribute}' to a number.`
					}
				end,
			},
			
			textSize = {
				Name = "TextSize",
				Type = function(Attribute)
					local Number = tonumber(Attribute)
					return {
						Success = Number ~= nil,
						Response = Number or `Unable to convert '{Attribute}' to a number.`
					}
				end,
			}
		},
		
		Redact = function(Snippet)
			Snippet.Label.Text = Snippet.Data
			local Size = Snippet.Label.Size
			
			Snippet.Label.Size = UDim2.new(Size.X.Scale, Size.X.Offset, Snippet.Attributes.Size or Size.Y.Scale, Size.Y.Offset)
			Snippet.Label.TextSize = Snippet.Attributes.TextSize or Snippet.Label.TextSize
		end,
	},
	
	{
		Type = "Code",
		Snippet = "code",
		
		Attributes = {
			size = {
				Name = "Size",
				Type = function(Attribute)
					local Number = tonumber(Attribute)
					return {
						Success = Number ~= nil,
						Response = Number or `Unable to convert '{Attribute}' to a number.`
					}
				end,
			},
			
			textSize = {
				Name = "TextSize",
				Type = function(Attribute)
					local Number = tonumber(Attribute)
					return {
						Success = Number ~= nil,
						Response = Number or `Unable to convert '{Attribute}' to a number.`
					}
				end,
			}
		},
		
		Redact = function(Snippet)
			Snippet.Label.Scrollable.Input.Text = Snippet.Data
			local FirstTime = false
			local Since
			
			local Plus
			local Minus
			
			-- TODO optimize probably.
			local Connections = {
				Highlight.highlight({
					textObject = Snippet.Label.Scrollable.Input,
				}),
				
				UserInputService.InputChanged:Connect(function(InputKey, GameProcessedEvent)
					if not Snippet.Label.Scrollable.Input.Focused or InputKey.UserInputType ~= Enum.UserInputType.MouseWheel then
						return
					end

					local Up = InputKey.Position.Z > 0 
					local Down = InputKey.Position.Z <= 0

					Plus = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Up
					Minus = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Down

					local IsHolding = (Plus or Minus)
					Since = IsHolding and tick() or Since

					if IsHolding then
						FirstTime = true
					end
				end),
				
				_G.GAdmin.Render(function()
					Snippet.Label.Scrollable.Input_Resizer.TextSize = Snippet.Label.Scrollable.Input.TextSize
					if not Plus and not Minus then
						return
					end

					local ToAdd = Plus and 1 or -1
					if not FirstTime then--if tick() - self.Arguments.Holding.Since < 1 and not self.Arguments.FirstTime then
						return
					end

					FirstTime = false
					Snippet.Label.Scrollable.Input.TextSize = math.clamp(Snippet.Label.Scrollable.Input.TextSize + ToAdd, 8, 30)
				end)
			}
			
			local Size = Snippet.Label.Size
			Snippet.Label.Size = UDim2.new(Size.X.Scale, Size.X.Offset, Snippet.Attributes.Size or Size.Y.Scale, Size.Y.Offset)
			
			Snippet.Label.Scrollable.Input.TextSize = Snippet.Attributes.TextSize or Snippet.Label.Scrollable.Input.TextSize
			Snippet.Label.Scrollable.Input_Resizer.TextSize = Snippet.Label.Scrollable.Input.TextSize
			
			Snippet.Label.BackgroundTransparency = 0
			return Snippet, Connections
		end,
	}
}