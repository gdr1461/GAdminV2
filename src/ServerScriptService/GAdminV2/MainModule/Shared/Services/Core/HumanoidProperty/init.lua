local Property = {}
Property.Supported = require(script.Properties)
Property.Actions = require(script.Actions)

function Property:Set(Humanoid, Action, Property, Value, PassError)
	local Supported = self:Find(Property)
	local Success, Error = self:IsValid(Property, Action, Value)
	
	if not Success then
		if PassError then
			return false, Error
		end
		
		warn(`[GAdmin Core]: HumanoidProperty :: {Error}`)
		return
	end
	
	local ActionInfo = self:GetAction(Action)
	local FinalValue = Supported.Handle(Humanoid, ActionInfo.Handle, Value)
	
	return true, FinalValue
end

function Property:GetList(AliasCombined)
	local Properties = {}
	
	for i, Property in ipairs(self.Supported) do
		local Info = AliasCombined and `{Property.Name} / {table.concat(Property.Alias, " / ")}` or Property.Name
		table.insert(Properties, Info)
	end
	
	return Properties
end

function Property:Find(Property)
	for i, Supported in ipairs(self.Supported) do
		if Supported.Name ~= Property and not table.find(Supported.Alias, Property) then
			continue
		end
		
		return Supported
	end
end

function Property:IsValid(Property, Action, Value)
	local Supported = self:Find(Property)
	if not Supported then
		return false, `Property '{Property}' is not supported.`
	end
	
	if not self:HasAction(Property, Action) then
		return false, `Property '{Property}' has no action '{Action}'.`
	end
	
	local ValueType = type(Value)
	for i, Type in ipairs(Supported.Types) do
		if ValueType ~= Type then
			continue
		end
		
		return true
	end
	
	return false, `Type of specified value is not supported for property '{Property}'.`
end

function Property:IsTypes(Property, Types)
	local Supported = self:Find(Property)
	if not Supported then
		return {}
	end
	
	for i, Type in ipairs(Types) do
		for i, PropertyType in ipairs(Supported.Types) do
			if PropertyType ~= Type then
				continue
			end

			return true
		end
	end
	
	return false
end

function Property:HasAction(Property, Action)
	local Actions = self:GetPropertyActions(Property)
	return table.find(Actions, Action) ~= nil
end

function Property:GetAction(Action)
	for i, ActionInfo in ipairs(self.Actions) do
		if ActionInfo.Name ~= Action then
			continue
		end
		
		return ActionInfo
	end
end

function Property:GetPropertyActions(Property)
	local Supported = self:Find(Property)
	if not Supported then
		return {}
	end
	
	local Actions = {}
	for i, Action in ipairs(self.Actions) do
		if not self:IsTypes(Property, Action.Types) then
			continue
		end
		
		table.insert(Actions, Action.Name)
	end
	
	return Actions
end

return Property