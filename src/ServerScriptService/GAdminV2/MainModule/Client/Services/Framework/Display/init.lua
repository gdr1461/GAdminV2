--== << Services >>
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TweenService = game:GetService("TweenService")
local Main = script:FindFirstAncestor("GAdminShared")

local UI = require(Main.Client.Services.UI)
local Sound = require(Main.Shared.Services.Sound)
local DraggableMeta = require(script.Draggable)
--==

return {
	["MainButton"] = function(Frame, Options)
		Frame.Parent = UI.Gui.MainFrame.Places.Main.Pages["1"].List
		Frame.Name = Options.Name
		Frame.LayoutOrder = Options.Order
		Frame.Text = Options.Text
	end,
	
	["Popup"] = function(Frame, Options)
		local Break = false
		local Container = Instance.new("Frame")
		
		Container.Size = UDim2.fromScale(1, 0)
		Container.BackgroundTransparency = 1
		
		Container.Name = `Popup`
		Container.Parent = UI.Gui.Notifications
		
		UI.Popups += 1
		Container.LayoutOrder = UI.Popups
		
		Frame.Parent = Container
		Frame.Position = UDim2.fromScale(1, 0)
		
		local Info = TweenInfo.new(.2, Enum.EasingStyle.Back)
		local Tween = TweenService:Create(Container, Info, {Size = UDim2.fromScale(1, 1)})
		
		Tween:Play()
		Tween.Completed:Wait()
		TweenService:Create(Frame, Info, {Position = UDim2.fromScale(0, 0)}):Play()
		
		Frame.Top.Title.Text = Options.Display or Options.Title or "Notification"
		Frame.Content.Text = Options.Text and tostring(Options.Text) or "N/A"
		Frame.Content.TextScaled = not Frame.Content.TextFits
		
		local Connection1 = Frame.Top.Close.MouseEnter:Connect(function()
			Sound:Play("Buttons", "Hover1")
			Frame.Top.Close.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
		end)

		local Connection2 = Frame.Top.Close.MouseLeave:Connect(function()
			Frame.Top.Close.TextColor3 = Color3.new(1, 1, 1)
		end)
		
		local Connection3
		local Connection4
		
		if Options.Interact then
			Connection3 = Frame.Interact.MouseEnter:Connect(function()
				Sound:Play("Buttons", "Hover1")
				Frame.Content.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
			end)

			Connection4 = Frame.Interact.MouseLeave:Connect(function()
				Frame.Content.TextColor3 = Color3.new(1, 1, 1)
			end)
			
			Frame.Interact.Activated:Once(function()
				Sound:Play("Buttons", "Click1")
				Break = true
				Options.Interact()
			end)
		end
		
		local Thread = task.spawn(function()
			Frame.Top.Progress.Bar.Size = UDim2.fromScale(1, 1)
			local Until = tick() + Options.Time
			
			repeat
				local Time = Until - tick()
				Break = Time <= 0
				
				Frame.Top.Progress.Bar.Size = UDim2.fromScale(Time / Options.Time, 1)
				task.wait()
			until Break
			
			Frame.Top.Progress.Bar.Size = UDim2.fromScale(0, 1)
			local Tween = TweenService:Create(Frame, Info, {Position = UDim2.fromScale(1, 0)})
			Tween:Play()
			
			Tween.Completed:Wait()
			local Tween = TweenService:Create(Container, Info, {Size = UDim2.fromScale(1, 0)})
			
			Tween:Play()
			Connection1:Disconnect()
			Connection2:Disconnect()
			
			if Connection3 then
				Connection3:Disconnect()
				Connection4:Disconnect()
			end
			
			Tween.Completed:Once(function()
				Container:Destroy()
			end)
			
			if Options.OnEnd then
				Options.OnEnd(Frame, Options)
			end
		end)
		
		Frame.Top.Close.Activated:Once(function()
			Sound:Play("Buttons", "Click1")
			Break = true
		end)
	end,
	
	["Draggable"] = function(TempFrame, Frame)
		TempFrame:Destroy()
		local Draggable = DraggableMeta.new(Frame)
		return Draggable
	end,
}