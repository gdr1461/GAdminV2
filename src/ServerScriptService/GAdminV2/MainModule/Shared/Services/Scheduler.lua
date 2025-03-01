local Scheduler = {}
Scheduler.Groups = {
	Global = {}
}

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

function Scheduler:AddGroup(Name)
	if self.Groups[Name] then
		warn(`[GAdmin Scheduler]: Group with name '{Name}' already exists.`)
		return
	end
	
	self.Groups[Name] = {}
end

function Scheduler:RemoveGroup(Name)
	if not self.Groups[Name] then
		return
	end
	
	table.clear(self.Groups[Name])
	self.Groups[Name] = nil
end

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

function Scheduler:Remove(Group, Id)
	local Interval, Index = self:Find(Group, Id)
	if not Interval then
		return
	end
	
	table.remove(self.Groups[Group], Index)
end

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

function Scheduler:IsReady(Group, Id)
	local Interval = self:Find(Group, Id)
	if not Interval then
		return false
	end
	
	return tick() - Interval.LastUpdate >= Interval.Time
end

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