local NewConnection = require(script.Parent.Connection)
local Signal = {}

Signal.__type = "GSignal Pro Object"
Signal.__index = Signal

function Signal:__tostring()
	return self.Id
end

function Signal:__call(...)
	return self:Fire(...)
end

function Signal:__len()
	return self.Connections
end

function Signal:__eq(Value)
	return type(Value) == "table" and Value.__type == "GSignal Pro Object" and self.Id == Value.Id
end

function Signal:Freeze()
	if self.State == "Frozen" then
		warn(`[GSignal]: {self} :: Signal is already frozen.`)
		return
	end
	
	self.State = "Frozen"
end

function Signal:UnFreeze()
	if self.State ~= "Frozen" then
		warn(`[GSignal]: {self} :: Signal is already unfrozen.`)
		return
	end
	
	self.State = self.__Middleware and "Secured" or "Default"
end

function Signal:Connect(Function)
	return NewConnection(self, Function)
end

function Signal:Once(Function)
	local Connection
	Connection = NewConnection(self, function(...)
		Connection:Disconnect()
		return Function(...)
	end)
	
	return Connection
end

function Signal:Wait()
	local Thread = coroutine.running()
	self:Once(function(...)
		task.spawn(Thread, ...)
	end)
	
	return coroutine.yield()
end

function Signal:Fire(...)
	if self.State == "Frozen" then
		return
	end
	
	local Arguments = {...}
	if self.__Middlewares.Entry then
		local Callback = self.__Middlewares.Entry(self, ...)
		if not Callback then
			return
		end
	end
	
	if self.__Middlewares.Redact then
		local Callback = self.__Middlewares.Redact(self, Arguments)
		for i, v in ipairs(Callback) do
			Arguments[i] = v
		end
		
		if #Callback > #Arguments then
			for i = #Callback + 1, #Arguments do
				table.remove(Arguments, i)
			end
		end
	end
	
	local Start = os.clock()
	for i, Connection in ipairs(self.__Connections) do
		Connection:__Fire(unpack(Arguments))
	end
	
	if self.Debug then
		print(`[GSignal]: {self} :: Called {self.Connections} connection{self.Connections > 1 and "s" or ""} in {os.clock() - Start} seconds.`)
	end
end

function Signal:DisconnectAll()
	for i, Connection in ipairs(self.__Connections) do
		Connection:Disconnect()
	end
end

function Signal:Destroy()
	self:DisconnectAll()
	table.clear(self)
	
	setmetatable(self, nil)
	self.State = "Destroyed"
end

return Signal