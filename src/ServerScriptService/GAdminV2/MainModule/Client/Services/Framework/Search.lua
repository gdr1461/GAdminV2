--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Sound = require(Main.Shared.Services.Sound)
local GSignal = require(Main.Shared.Services.GSignalPro)
--==

function CopyTable(Table)
	local Copy = {}
	for i, v in pairs(Table) do
		if type(v) == "table" then
			Copy[i] = CopyTable(v)
			continue
		end
		
		Copy[i] = v
	end
	
	return Copy
end

local Search = {}
Search.__type = "GAdmin Search"
Search.__index = Search

function Search:Search(String)
	self.Current = String
	local Results, Empty = self:RawSearch(String)
	self:ShowResults(Results, Empty)
	self.OnSearch:Fire(String, Results)
end

function Search:Clear()
	self:Search("")
end

function Search:SetTemplate(Frame)
	local Input = ""
	table.insert(self.__Connections, Frame.Search.MouseEnter:Connect(function()
		Sound:Play("Buttons", "Hover1")
		self:Search(Input)
	end))
	
	table.insert(self.__Connections, Frame.Search.Activated:Connect(function()
		Sound:Play("Buttons", "Click1")
		self:Search(Input)
	end))
	
	table.insert(self.__Connections, Frame.Input.Input.FocusLost:Connect(function(EnterPressed)
		if not EnterPressed then
			return
		end
		
		self:Search(Input)
	end))
	
	table.insert(self.__Connections, Frame.Input.Input:GetPropertyChangedSignal("Text"):Connect(function()
		Input = Frame.Input.Input.Text
	end))
end

function Search:ShowResults(Results, Empty)
	for i, Frame in ipairs(self.Frame:GetChildren()) do
		if not table.find({"TextButton", "TextLabel", "Frame", "ScrollingFrame", "ImageButton", "ImageLabel"}, Frame.ClassName) then
			continue
		end

		Frame.Visible = false
	end
	
	for i, Item in ipairs(Results) do
		local Frame = self.Frame:WaitForChild(Item.Frame)
		if not Frame:GetAttribute("Search_Position") then
			Frame:SetAttribute("Search_Position", Frame.LayoutOrder)
		end
		
		Frame.Visible = true
		Frame.LayoutOrder = Empty and Frame:GetAttribute("Search_Position") or i
	end
end

function Search:RawSearch(String: string)
	local IsEmptyString = String:gsub("%s+", "") == ""
	local Items = {}
	
	local FirstSearch = {}
	local SecondSearch = {}
	
	for i, Item in ipairs(self.Items) do
		local IsSecondSearch = false
		local IsValid
		
		for i, Searchable in ipairs(Item.Search) do
			Searchable = type(Searchable) == "string" and Searchable or tostring(Searchable)
			if Searchable:lower():sub(1, #String) ~= String:lower() and not IsEmptyString then
				if Searchable:lower():find(String:lower()) then
					local ItemCopy = CopyTable(Item)
					ItemCopy.Searched = IsValid
					
					IsSecondSearch = true
					table.insert(SecondSearch, ItemCopy)
					continue
				end
				
				continue
			end
			
			IsValid = Searchable
			break
		end
		
		if not IsValid or IsSecondSearch then
			continue
		end

		local ItemCopy = CopyTable(Item)
		ItemCopy.Searched = IsValid
		table.insert(FirstSearch, ItemCopy)
	end
	
	Items = FirstSearch
	for i, v in ipairs(SecondSearch) do
		local Invalid = false
		for i, Item in ipairs(FirstSearch) do
			if Item.Frame ~= v.Frame then
				continue
			end
			
			Invalid = true
			table.insert(Items, Item)
			break
		end
		
		if Invalid then
			continue
		end
		
		table.insert(Items, v)
	end
	
	return Items, IsEmptyString
end

function Search:AddItems(Items)
	for i, Item in ipairs(Items) do
		table.insert(self.Items, Item)
	end
end

function Search:Destroy()
	self.OnSearch:Destroy()
	for i, Connection in ipairs(self.__Connections) do
		Connection:Disconnect()
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

return {
	new = function(Frame, Items)
		Items = Items or {}
		local NewSearch = setmetatable({}, Search)
		
		NewSearch.__Connections = {}
		NewSearch.Current = ""
		
		NewSearch.Frame = Frame
		NewSearch.Items = Items
		
		NewSearch.OnSearch = GSignal.new()
		return NewSearch
	end,
}