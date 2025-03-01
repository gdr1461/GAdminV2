local Types = require(script.Types)
local SignalMeta = require(script.Signal)

local Proxy = newproxy(true)
local GSignal: Types.GSignal = getmetatable(Proxy)

GSignal.__type = "GSignal Pro"
GSignal.__version = "v0.0.2"

GSignal.__metatable = "[GSignal Pro]: Metatable methods are restricted."
GSignal.Signals = {}

function GSignal:__tostring()
	return self.__type, self.__version
end

function GSignal:__index(Key)
	return GSignal[Key]
end

function GSignal:GetAncestorInstance(FullName)
	
end

function GSignal:GetAncestor(Layer)
	Layer = Layer or 1
	local Traceback = debug.traceback()
	local Sources = {}
	
	local Current = 0
	for Line in Traceback:gmatch("[^\n]+") do
		Current += 1
		local Word = Line:match("([^:]+):")
		
		if not Word then
			continue
		end
		
		local LastWord = Word:match("%w+$")
		if table.find(Sources, LastWord) then
			continue
		end

		table.insert(Sources, LastWord)
		if Current >= Layer then
			return LastWord
		end
	end
end

function GSignal.new(...)
	return GSignal:Create(...)
end

function GSignal:Create(Config)
	Config = Config or {}
	Config.Middlewares = Config.Middlewares or {}
	
	local HasMiddlewares = Config.Middlewares.Entry ~= nil or Config.Middlewares.Redact ~= nil
	local Signal = setmetatable({}, SignalMeta)
	
	Signal.__Middlewares = table.freeze(Config.Middlewares)
	Signal.State = HasMiddlewares and "Secured" or "Default"
	
	Signal.Ancestor = self:GetAncestor(2)
	Signal.Id = `GSignal::{Signal.Ancestor}#{#self:GetAll(Signal.Ancestor) + 1}`
	
	Signal.Connections = 0
	Signal.__Connections = {}
	
	function Signal:Destroy()
		GSignal.Signals[self.Id] = nil
		SignalMeta.Destroy(self)
	end
	
	self.Signals[Signal.Id] = Signal
	return Signal
end

function GSignal:Get(Id)
	local Ancestor = self:GetAncestor(2)
	local RawId = Id or 1
	
	local Id = `GSignal::{Ancestor}#{RawId}`
	return self.Signals[Id]
end

function GSignal:GetAll(Name)
	Name = Name or self:GetAncestor(2)
	local Signals = {}
	
	for Id, Signal in pairs(self.Signals) do
		if not Id:sub(9, #Id):find(Name) then
			continue
		end
		
		table.insert(Signals, Signal)
	end
	
	return Signals
end

return Proxy :: Types.GSignal