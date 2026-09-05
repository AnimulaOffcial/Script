--!strict
-- Supported Free game identifiers. This file contains no gameplay features.

local FreeGames = {
	Tier = "Free",
	PlaceIds = {
		Arsenal = 286090429,
		Rivals = 17625359962,
	},
}

function FreeGames:GetName(placeId: number): string?
	for name, id in pairs(self.PlaceIds) do
		if id == placeId then return name end
	end
	return nil
end

function FreeGames:IsSupported(placeId: number): boolean
	return self:GetName(placeId) ~= nil
end

return FreeGames
