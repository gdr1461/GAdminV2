--== << Services >>
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Main = ReplicatedStorage:WaitForChild("GAdminShared")

local Remote = require(Main.Shared.Services.Remote)
local Enviorment = require(script.Enviorment)
--==

local Executor = {}
Executor.__index = Executor
Executor.__type = "GAdmin Loadstring Executor"

function Executor:Run(CodeOrJob, Caller, Yield)
	local JobEnv = Enviorment.new()
	local String = type(CodeOrJob) == "table" and CodeOrJob.String or CodeOrJob
	
	local Function = loadstring(String, "GA_Code")
	if not Function then
		return
	end
	
	local Job = {
		Caller = Caller and Caller.Name or "N/A",
		String = String,
		Function = Function,
		Task = coroutine.create(Function)
	}

	table.insert(self.Jobs, Job)
	local Success, Response = coroutine.resume(Job.Task, Caller, unpack(JobEnv.Arguments))
	
	self.JobIds += 1
	Job.JobId = self.JobIds
	
	if Success then
		if coroutine.status(Job.Task) ~= "dead" and Yield then
			local Cache = {}
			repeat
				task.wait()
				local Data = Enviorment.GetData(JobEnv)
				
				if #Data == #Cache then
					continue
				end
				
				self:SetOutput(Caller, Data)
				Cache = Data
			until not Job.Task or coroutine.status(Job.Task) == "dead" or not Caller.Parent
		end
		
		Response = Enviorment.GetData(JobEnv)
	end

	Response = Success and Response or {Response:gsub(`%[string "GA_Code"%]:`, "")}
	return {
		Success = Success,
		Response = Response,

		Job = self:GetJob(Job.JobId),
		JobId = Job.JobId
	}
end

function Executor:GetJobs()
	local Jobs = {}
	for i, Job in ipairs(self.Jobs) do
		table.insert(Jobs, {
			Caller = Job.Caller,
			JobId = Job.JobId,
			Index = i,
			Data = Job.String,
			Status = coroutine.status(Job.Task),
		})
	end
	
	return Jobs
end

function Executor:GetJob(JobId)
	if not self.Jobs[JobId] then
		return
	end

	local Job = self.Jobs[JobId]
	return {
		Caller = Job.Caller,
		JobId = Job.JobId,
		Index = JobId,
		Data = Job.String,
		Status = coroutine.status(Job.Task),
	}
end

function Executor:SetOutput(Caller, Output)
	Remote:Fire("RunCodeCallback", Caller, "SetOutput", Output)
end

function Executor:Recall(JobId, Caller)
	if not self.Jobs[JobId] then
		return
	end
	
	local Response = self:Run(self.Jobs[JobId], Caller)
	Remote:FireAll("RunCodeCallback", "RefreshThreads", self:GetJobs())
	return Response
end

function Executor:Cancel(JobId)
	if not self.Jobs[JobId] then
		return
	end

	coroutine.close(self.Jobs[JobId].Task)
	self.Jobs[JobId] = {}
	
	table.remove(self.Jobs, JobId)
	Remote:FireAll("RunCodeCallback", "RefreshThreads", self:GetJobs())
end

return {
	new = function()
		local NewExecutor = setmetatable({}, Executor)
		NewExecutor.Jobs = {}
		NewExecutor.JobIds = 0
		
		return NewExecutor
	end,
}