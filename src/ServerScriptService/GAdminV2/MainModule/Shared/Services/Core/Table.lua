local Table = {}

function Table:GetChunk(Table, Size, Index)
	local Limit = #Table
	Index = Index or math.ceil(Limit / Size)

	local Start = (Index - 1) * Size + 1
	local End = math.min(Start + Size - 1, Limit)

	local Chunk = {}
	table.move(Table, Start, End, 1, Chunk)

	local IsLast = End >= Limit
	return Chunk, IsLast
end

function Table:GetPart(Table, Size)
	local Limit = #Table
	local Part = {}
	
	table.move(Table, math.max(Limit - Size + 1, 1), Limit, 1, Part)
	return Part
end

return Table