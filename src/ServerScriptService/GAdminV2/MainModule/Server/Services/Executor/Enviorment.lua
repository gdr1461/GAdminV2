--== << Services >>
local Main = script:FindFirstAncestor("Server")
local API = require(Main.Services.API)
--==

return {
	new = function()
		local Enviorment = {}
		Enviorment.Data = {}
		
		Enviorment.Arguments = {
			function(...)
				print(...)
				table.insert(Enviorment.Data, {
					Type = "print",
					Line = debug.traceback(nil, 2):gsub(`%[string "GA_Code"%]:`, ""):gsub("%s+", ""),
					Data = {...}
				})
			end,
			
			function(...)
				warn(...)
				table.insert(Enviorment.Data, {
					Type = "warn",
					Line = debug.traceback(nil, 2):gsub(`%[string "GA_Code"%]:`, ""):gsub("%s+", ""),
					Data = {...}
				})
			end,
			
			function(Caller, Command, Arguments)
				if typeof(Caller) ~= "Instance" or not Caller:IsA("Player") then
					table.insert(Enviorment.Data, {
						Type = "error",
						Line = debug.traceback(nil, 2):gsub(`%[string "GA_Code"%]:`, ""):gsub("%s+", ""),
						Data = {`Player {Caller} doesn't exist.`}
					})
					
					return false
				end
				
				if type(Command) ~= "string" then
					table.insert(Enviorment.Data, {
						Type = "error",
						Line = debug.traceback(nil, 2):gsub(`%[string "GA_Code"%]:`, ""):gsub("%s+", ""),
						Data = {`Command must be a string type.`}
					})
					
					return false
				end
				
				Arguments = Arguments or {}
				if type(Arguments) ~= "table" then
					table.insert(Enviorment.Data, {
						Type = "error",
						Line = debug.traceback(nil, 2):gsub(`%[string "GA_Code"%]:`, ""):gsub("%s+", ""),
						Data = {`Arguments must be a table type.`}
					})
					
					return false
				end
				
				local Prefix = API:GetPrefix(Caller)
				if not Prefix then
					return false
				end
				
				for i, Argument in ipairs(Arguments) do
					Arguments[i] = tostring(Argument)
				end
				
				local Message = `{Prefix}{Command} {table.concat(Arguments, " ")}`
				local Success = API.PlayerAPI:OnMessage(Caller, Message)
				
				return Success
			end,
		}
		
		return Enviorment
	end,
	
	GetData = function(Enviorment)
		local Data = {}
		
		for i, Call in ipairs(Enviorment.Data) do
			local CallData = {}
			for i, v in ipairs(Call.Data) do
				table.insert(CallData, tostring(v))
			end
			
			table.insert(Data, `{Call.Type}:{Call.Line}: {table.concat(CallData, " ")}`)
		end
		
		return Data
	end,
}