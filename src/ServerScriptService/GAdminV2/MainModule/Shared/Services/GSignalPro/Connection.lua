local ConnectionMeta = {}
ConnectionMeta.__index = ConnectionMeta

function ConnectionMeta:__Fire(...)
	task.spawn(function(...)
		return self.Function(...)
	end, ...)
end

function ConnectionMeta:Disconnect()
	local Index = table.find(self.Signal.__Connections, self)
	if Index then
		table.remove(self.Signal.__Connections, Index)
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

return function(Signal, Function)
	local Connection = setmetatable({}, ConnectionMeta)
	Connection.Signal = Signal
	Connection.Function = Function
	
	table.insert(Signal.__Connections, Connection)
	Signal.Connections = #Signal.__Connections
	
	return Connection
end