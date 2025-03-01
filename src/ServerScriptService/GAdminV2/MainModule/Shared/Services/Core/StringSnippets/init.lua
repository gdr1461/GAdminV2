--== << Services >>
local Main = script:FindFirstAncestor("GAdminShared")
local Assets = Main.Shared.Assets
local GuiAssets = Assets.Gui
local SnippetAssets = GuiAssets.StringSnippets
--==

local Snippets = {}
Snippets.Content = require(script.Content)

function Snippets:Format(String: string)
	local Result = {}
	local Pattern = "<(%w+)(.-)>(.-)</%1>"
	local Last = 1

	for Tag, RawAttributes, Snippet in String:gmatch(Pattern) do
		local Start, End = String:find(`<{Tag}{RawAttributes}>{Snippet}</{Tag}>`, Last, true)
		if Start > Last then
			table.insert(Result, {
				Type = "Normal",
				Data = String:sub(Last, Start - 1),
				Attributes = {},
			})
		end
	
		for i, Type in ipairs(self.Content) do
			if Type.Snippet ~= Tag then
				continue
			end
			
			local Attributes = {}
			for Key, Value in RawAttributes:gmatch("(%w+)=\"(.-)\"") do
				if not Type.Attributes or not Type.Attributes[Key] then
					warn(`[GAdmin StringSnippets]: Attribute '{Key}' is not valid for snippet '{Type.Type}'.`)
					continue
				end
				
				local AttributeData = Type.Attributes[Key]
				local Request = AttributeData.Type(Value)
				
				if not Request.Success then
					warn(`[GAdmin StringSnippets]: Attribute '{Key}' :: {Request.Response}`)
					continue
				end

				Attributes[AttributeData.Name] = Request.Response
			end

			table.insert(Result, {
				Type = Type.Type,
				Data = Snippet,
				Attributes = Attributes,
			})

			break
		end

		Last = End + 1
	end

	if Last <= #String then
		table.insert(Result, {
			Type = "Normal",
			Data = String:sub(Last),
			Attributes = {},
		})
	end

	return Result
end

function Snippets:Find(Type)
	for i, Snippet in ipairs(self.Content) do
		if Type ~= Snippet.Type then
			continue
		end

		return Snippet
	end
end

function Snippets:ToLabel(Data, Template, Parent, Size)
	Size = Size or (Template and Template.Size or UDim2.fromScale(1, .2))
	local Labels = {}
	
	for i, Snippet in ipairs(Data) do
		local Connections = {}
		local Type = self:Find(Snippet.Type)

		local SnippetTemplate = SnippetAssets:FindFirstChild(Snippet.Type)
		local Label = SnippetTemplate and SnippetTemplate:Clone() or (Template and Template:Clone() or Instance.new("TextLabel"))

		Label.Name = i
		Label.Parent = Parent
		Label.Size = Size

		Snippet.Label = Label
		if Type and Type.Redact then
			Snippet, Connections = Type.Redact(Snippet)
		end

		Connections = Connections or {}
		table.insert(Connections, Label:GetPropertyChangedSignal("Parent"):Connect(function()
			if Label.Parent then
				return
			end

			for i, Connection in ipairs(Connections) do
				Connection:Disconnect()
			end
		end))

		table.insert(Labels, Label)
	end

	return Labels
end

function Snippets:MoveLabel(Labels, Position, Spacing)
	Position = Position or UDim2.fromScale(0)
	Spacing = Spacing or 5

	local YOffset = Position.Y.Offset
	for i, Label in ipairs(Labels) do
		Label.Position = UDim2.new(Position.X.Scale, Position.X.Offset, 0, YOffset)
		YOffset = YOffset + Label.AbsoluteSize.Y + Spacing
	end
end

return Snippets