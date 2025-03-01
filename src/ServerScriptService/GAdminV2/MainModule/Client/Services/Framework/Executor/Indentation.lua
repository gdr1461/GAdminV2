local Indentation = {}

function Indentation:Indent(String)
	local Lines = String:split("\n")
	local Indented = {}
	local Level = 0

	for i, Line in ipairs(Lines) do
		local Trimmed = Line:match("^%s*(.-)%s*$")
		if Trimmed:match("^end$") or Trimmed:match("^elseif ") or Trimmed:match("^else$") then
			Level = math.max(Level - 1, 0)
		end

		table.insert(Indented, string.rep("\t", Level) .. Trimmed)
		if Trimmed:match("do$") or Trimmed:match("then$") or Trimmed:match("function") then
			Level = Level + 1
		end
	end

	return table.concat(Indented, "\n"), Level
end

function Indentation:FillWords(String)
	local Lines = string.split(String, "\n")
	local Filled = {}
	local FillAdded = {}

	for i, Line in ipairs(Lines) do
		local Trimmed = Line:match("^%s*(.-)%s*$")
		local Added
		
		if Trimmed:match("^if .-$") and not Trimmed:match("then$") then
			Added = " then"
			Trimmed = Trimmed .. Added
		end

		if (Trimmed:match("^for .-$") or Trimmed:match("^while .-$")) and not Trimmed:match("do$") then
			Added = " do"
			Trimmed = Trimmed .. Added
		end

		table.insert(Filled, Trimmed)
		table.insert(FillAdded, Added)
	end

	return table.concat(Filled, "\n"), FillAdded
end

function Indentation:CloseBlocks(String)
	local Lines = string.split(String, "\n")
	local Open = {}
	local Closed = {}

	for i, Line in ipairs(Lines) do
		local Trimmed = Line:match("^%s*(.-)%s*$")
		if Trimmed:match("do$") or Trimmed:match("then$") or Trimmed:match("function") then
			table.insert(Open, {
				Index = #Closed + 1,
				Line = Trimmed
			})
		end

		if Trimmed:match("^end$") and #Open > 0 then
			table.remove(Open)
		end

		table.insert(Closed, Trimmed)
	end

	for i = #Open, 1, -1 do
		local Index = Open[i].Index
		--if Closed[Index] then
		--	Closed[Index] = `end {Closed[Index]}`
		--	continue
		--end
		
		table.insert(Closed, Index + 1, " ")
		Closed[Index + 2] ..= "end"
	end

	return table.concat(Closed, "\n")
end

return Indentation