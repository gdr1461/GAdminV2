local UI = {}

function UI:Load(player, Builder)
	for i, Place in ipairs(script:GetChildren()) do
		Builder:LoadPlace(Place, Place.Frame)
	end
end

return UI