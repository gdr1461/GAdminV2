--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets

local Bin = Assets.Bin
local Sounds = Assets.Sounds
--==

local Proxy = newproxy(true)
local Sound = getmetatable(Proxy)

Sound.__type = "GAdmin Sound"
Sound.__metatable = "[GAdmin Sound]: Metatable methods are restricted."

function Sound:__tostring()
	return self.__type
end

function Sound:__index(Key)
	return Sound[Key]
end

function Sound:Play(DataOrCategory, Name)
	local Data = type(DataOrCategory) == "table" and DataOrCategory or {
		Category = DataOrCategory,
		Name = Name,
	}
	
	local Folder = Sounds:FindFirstChild(Data.Category)
	if not Folder then
		warn(`[{self.__type}]: Sound category '{Data.Category}' is invalid.`)
		return
	end
	
	local SoundObject = Folder:FindFirstChild(Data.Name)
	if not SoundObject then
		warn(`[{self.__type}]: Sound '{Data.Name}' does not exist in category '{Data.Category}'.`)
		return
	end
	
	if Data.Original then
		SoundObject:Play()
		return
	end
	
	local Copy = SoundObject:Clone()
	Copy.Parent = Bin
	
	Copy:Play()
	Copy.Ended:Once(function()
		Copy:Destroy()
	end)
	
	return Copy
end

return Proxy