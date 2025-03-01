local Proxy = newproxy(true)
local Builder = getmetatable(Proxy)

Builder.__type = "GAdmin IBuilder"
Builder.__metatable = "[GAdmin IBuilder]: Metatable methods are restricted."

function Builder:__tostring()
	return self.__type
end

function Builder:__index(Key)
	return Builder[Key]
end

function Builder:Load(Interface)
	Builder.Interface = Interface
end

function Builder:GetPlaceData(Module)
	local Success, Place = pcall(function()
		return require(Module)
	end)
	
	return Success, Place
end

function Builder:LoadPlace(Data, Frame, Override)
	if typeof(Data) == "Instance" then
		local Success, Place = self:GetPlaceData(Data)
		if not Success then
			warn(`[{self.__type}]: Place '{Data}' load fail :: {Place}`)
			return
		end
		
		Data = Place
	end
	
	if Frame then
		Frame.Name = Data.Name
		self:LoadPlaceFrame(Frame, Override)
	end
	
	self.Interface.PlaceData[Data.Name] = Data
end

function Builder:LoadPlaceFrame(Frame, Override)
	local Places = self.Interface.UI.MainFrame.Places
	local ExistingPlace = Places:FindFirstChild(Frame.Name)
	
	if ExistingPlace and not Override then
		warn(`[{self.__type}]: Place frame with name '{Frame.Name}' already exists.`)
		return
	end
	
	if ExistingPlace then
		ExistingPlace:Destroy()
	end
	
	Frame.Visible = false
	Frame.Parent = Places
end

return Builder