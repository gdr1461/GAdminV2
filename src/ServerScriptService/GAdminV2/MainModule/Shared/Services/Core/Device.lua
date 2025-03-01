--== << Services >>
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if not player then
	return {
		"Cannot access client only module from server side.",
		Incompatible = true,
	}
end

local Main = script:FindFirstAncestor("GAdminShared")
local UI = require(Main.Client.Services.UI)
--==

local Device = {}
Device.Controller = "Undefined"

Device.Inputs = {
	Keyboard = {Enum.UserInputType.Keyboard, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.MouseMovement, Enum.UserInputType.MouseWheel},
	Gamepad = {Enum.UserInputType.Gamepad1, Enum.UserInputType.Gamepad2, Enum.UserInputType.Gamepad3, Enum.UserInputType.Gamepad4, Enum.UserInputType.Gamepad5, Enum.UserInputType.Gamepad6, Enum.UserInputType.Gamepad7, Enum.UserInputType.Gamepad8},
	Touch = {Enum.UserInputType.Touch},
}

function Device:Load()
	UserInputService.InputBegan:Connect(function(InputKey)
		self:Update(InputKey)
	end)
	
	UserInputService.InputEnded:Connect(function(InputKey)
		self:Update(InputKey)
	end)
end

function Device:Update(InputKey)
	for Controller, Methods in pairs(self.Inputs) do
		if not table.find(Methods, InputKey.UserInputType) then
			continue
		end

		self.Controller = Controller
		break
	end
end

function Device:Get()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled and UI.Gui.AbsoluteSize.Y < 650 then
		return "Mobile"
	end

	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled and UI.Gui.AbsoluteSize.Y >= 650 then
		return "Tablet"
	end

	if game.GuiService:IsTenFootInterface() then
		return "Console"
	end

	return "Computer"
end

return Device