--[=[
	@class Scheduler
	@tag Shared
	Schedules function execution over time intervals.

	Location: `GAdmin.MainModule.Shared.Services.Scheduler`
]=]

--[=[
	@interface Scheduler
	@field Groups IntervalGroup
	@field Load () -> nil
	@field AddGroup (Name: string) -> nil
	@field RemoveGroup (Name: string) -> nil
	@field Insert (Group: string, Id: number, Function: () -> nil, Time: number) -> nil
	@field Remove (Group: string, Id: number) -> nil
	@field Find (Group: string, Id: number) -> Interval, number
	@field IsReady (Group: string, Id: number) -> boolean
	@field Call (Group: string, Id: number, Force: boolean) -> nil

	@within Scheduler
]=]

--[=[
	@type IntervalGroup {[string]: {Interval}}
	@within Scheduler
]=]

--[=[
	@interface Interval
	@field Id number -- The unique identifier of the interval.
	@field Callback thread -- The coroutine of the interval.
	@field Function () -> nil -- The function to run.
	@field Time number -- The time interval.
	@field LastUpdate number -- Last time the interval was updated.
	@within Scheduler
]=]

local Scheduler = {}

--[=[
	Currently running interval groups.
	@readonly
	@prop Groups IntervalGroup
	@within Scheduler
]=]
Scheduler.Groups = {
	Global = {}
}

--[=[
	Loads scheduler.

	@private
	@within Scheduler
	@return nil
]=]
function Scheduler:Load()
	_G.GAdmin.Render(function()
		for Group, Intervals in pairs(self.Groups) do
			for i, Interval in ipairs(Intervals) do
				if tick() - Interval.LastUpdate < Interval.Time then
					continue
				end
				
				if coroutine.status(Interval.Callback) == "dead" then
					Interval.Callback = coroutine.create(Interval.Function)
				end
				
				Interval.LastUpdate = tick()
				coroutine.resume(Interval.Callback)
			end
		end
	end)
	
	_G.GAdmin.Scheduler = self
end

--[=[
	Adds new interval group.

	@param Name string -- Unique name of the group.
	@within Scheduler
	@return nil
]=]
function Scheduler:AddGroup(Name)
	if self.Groups[Name] then
		warn(`[GAdmin Scheduler]: Group with name '{Name}' already exists.`)
		return
	end
	
	self.Groups[Name] = {}
end

--[=[
	Removes interval group.

	@param Name string -- Name of the group.
	@within Scheduler
	@return nil
]=]
function Scheduler:RemoveGroup(Name)
	if not self.Groups[Name] then
		return
	end
	
	table.clear(self.Groups[Name])
	self.Groups[Name] = nil
end

--[=[
	Inserts new interval.

	@param Group string -- Name of the group.
	@param Id number -- Unique identifier of the interval.
	@param Function () -> nil -- Function to run.
	@param Time number -- Time interval.
	@within Scheduler
	@return nil
]=]
function Scheduler:Insert(Group, Id, Function, Time)
	if not self.Groups[Group] then
		warn(`[GAdmin Scheduler]: Group with name '{Group}' is not valid.`)
		return
	end
	
	table.insert(self.Groups[Group], {
		Id = Id,
		Callback = coroutine.create(Function),
		Function = Function,
		Time = Time,
		LastUpdate = 0,
	})
end

--[=[
	Removes interval.

	@param Group string -- Name of the group.
	@param Id number -- Unique identifier of the interval.
	@within Scheduler
	@return nil
]=]
function Scheduler:Remove(Group, Id)
	local Interval, Index = self:Find(Group, Id)
	if not Interval then
		return
	end
	
	table.remove(self.Groups[Group], Index)
end

--[=[
	Finds interval.

	@param Group string -- Name of the group.
	@param Id number -- Unique identifier of the interval.
	@within Scheduler
	@return Interval, number
]=]
function Scheduler:Find(Group, Id)
	if not self.Groups[Group] then
		warn(`[GAdmin Scheduler]: Group with name '{Group}' is not valid.`)
		return
	end
	
	for i, Interval in ipairs(self.Groups[Group]) do
		if Interval.Id ~= Id then
			continue
		end
		
		return Interval, i
	end
end

--[=[
	Checks if interval is ready to be called.

	@param Group string -- Name of the group.
	@param Id number -- Unique identifier of the interval.
	@within Scheduler
	@return boolean
]=]
function Scheduler:IsReady(Group, Id)
	local Interval = self:Find(Group, Id)
	if not Interval then
		return false
	end
	
	return tick() - Interval.LastUpdate >= Interval.Time
end

--[=[
	Calls interval.

	@param Group string -- Name of the group.
	@param Id number -- Unique identifier of the interval.
	@param Force boolean -- Forces the interval to run even if interval is on cooldown.
	@within Scheduler
	@return nil
]=]
function Scheduler:Call(Group, Id, Force)
	local Interval, Index = self:Find(Group, Id)
	local IsReady = self:IsReady(Group, Id)
	
	if not IsReady and not Force then
		return
	end
	
	if coroutine.status(Interval.Callback) == "dead" then
		Interval.Callback = coroutine.create(Interval.Function)
	end
	
	coroutine.resume(Interval.Callback)
	Interval.LastUpdate = tick()
end

return Scheduler