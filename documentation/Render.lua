--[=[
    @class Render
    A function that allows you to run a function every frame. This is useful for rendering things that need to be updated every frame.
]=]

--[=[
    @type Render (Callback: (Delta: number) -> nil) -> {Disconnect: () -> nil}
    @within Render
]=]

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