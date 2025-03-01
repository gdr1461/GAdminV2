local RunService = game:GetService("RunService")
local Callbacks = {}

local Throttling = .01
local LastUpdate = tick()

RunService.PostSimulation:Connect(function(...)
	if tick() - LastUpdate < Throttling then
		return
	end
	
	LastUpdate = tick()
	for Callback in pairs(Callbacks) do
		task.spawn(Callback, ...)
	end
end)

return function(Callback)
	Callbacks[Callback] = true
	return {
		Disconnect = function()
			Callbacks[Callback] = nil
		end,
	}
end