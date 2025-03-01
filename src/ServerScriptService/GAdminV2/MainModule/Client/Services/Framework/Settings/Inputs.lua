--== << Services >>
local TweenService = game:GetService("TweenService")
local Main = script:FindFirstAncestor("GAdminShared")

local SliderConstructor = require(Main.Client.Services.Framework.Slider)
local ColorPicker = require(Main.Client.Services.ColorPicker)
local Sound = require(Main.Shared.Services.Sound)
--==

return {
	["Text"] = {
		Connect = function(Request, Callback)
			local Connections = {}
			
			table.insert(Connections, Request.Object.Input.FocusLost:Connect(function()
				local Input = Request.Object.Input.Text
				Callback(Input)
			end))
			
			return Connections
		end,
		
		Set = function(Request, Value)
			Request.Object.Input.Text = Value
		end,
		
		GetDefault = function(Request)
			return Request.Default
		end,
	},
	
	["Slider"] = {
		Connect = function(Request, Callback)
			local Connections = {}
			
			Connections.Slider = SliderConstructor.new(Request.Object, Request.Default.Min, Request.Default.Max)
			Connections.Slider:SetSlide(Request.Default.Slide)
			
			table.insert(Connections, Connections.Slider.OnUpdate:Connect(Callback))
			return Connections
		end,
		
		Set = function(Request, Value)
			Request.Connections.Slider:Set(Value or Request.Default.Min)
		end,
		
		GetDefault = function(Request)
			return Request.Default.Default
		end,
	},
	
	["Boolean"] = {
		Connect = function(Request, Callback)
			local Connections = {}
			local Info = TweenInfo.new(.2, Enum.EasingStyle.Sine)
			
			Connections.Tween1 = TweenService:Create(Request.Object.Slider, Info, {Position = UDim2.fromScale(0, 0), AnchorPoint = Vector2.new(0, 0)})
			Connections.Tween2 = TweenService:Create(Request.Object.Slider, Info, {Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0)})
			
			table.insert(Connections, Request.Object.Input.Activated:Connect(function()
				Sound:Play("Buttons", "Click1")
				local State = not Request.Object.Input:GetAttribute("State")
				
				Request.Object.Input:SetAttribute("State", State)
				Request.Object.State.Text = State and "Enabled" or "Disabled"
				Callback(State)
				
				Connections.Tween1:Pause()
				Connections.Tween2:Pause()
				
				if State then
					Connections.Tween1:Play()
					return
				end
				
				Connections.Tween2:Play()
				--Request.Object.Slider.Position = UDim2.fromScale(State and 0 or 1, 0)
				--Request.Object.Slider.AnchorPoint = Vector2.new(State and 0 or 1)
			end))
			
			return Connections
		end,
		
		Set = function(Request, Value)
			Request.Object.Input:SetAttribute("State", Value)
			Request.Object.State.Text = Value and "Enabled" or "Disabled"
			
			Request.Connections.Tween1:Pause()
			Request.Connections.Tween2:Pause()
			
			if Value then
				Request.Connections.Tween1:Play()
				return
			end
			
			Request.Connections.Tween2:Play()
			
			--Request.Object.Slider.Position = UDim2.fromScale(Value and 0 or 1, 0)
			--Request.Object.Slider.AnchorPoint = Vector2.new(Value and 0 or 1)
		end,
		
		GetDefault = function(Request)
			return Request.Default
		end,
	},
	
	["Color"] = {
		Connect = function(Request, Callback)
			local Color = Color3.fromHex(Request.Default.Color)
			local Connections = {}

			Connections.Pallete = ColorPicker.new(false)
			Connections.Pallete:SetColor(Color)
			Request.Object.BackgroundColor3 = Color
			
			task.spawn(function()
				repeat
					task.wait()
				until _G.GAdmin.Framework

				_G.GAdmin.Framework.Interface:SetHoverConfig(Connections.Pallete.frame, function(Object)
					local RawPosition = Request.Object.AbsolutePosition
					return UDim2.fromOffset(RawPosition.X, RawPosition.Y)
				end)
			end)
			
			table.insert(Connections, Request.Object.Activated:Connect(function()
				local Object = Connections.Pallete.frame
				local RawPosition = Request.Object.AbsolutePosition
				local Position = UDim2.fromOffset(RawPosition.X, RawPosition.Y)

				local AdjustedPosition = _G.GAdmin.Framework.Interface:GetFixedPosition(Object, Position)
				Object.Position = AdjustedPosition
				
				Connections.Pallete:Start()
			end))

			table.insert(Connections, Connections.Pallete.Changed:Connect(function(Color)
				Request.Object.BackgroundColor3 = Color
				Callback(Color:ToHex())
			end))
			
			return Connections
		end,

		Set = function(Request, Value)
			local Color = Color3.fromHex(Value)
			Request.Object.BackgroundColor3 = Color
			Request.Connections.Pallete:SetColor(Color)
		end,

		GetDefault = function(Request)
			return Request.Default.Default
		end,
	}
}