--!strict
-- Supported Premium game identifiers. This file contains no gameplay features.

local PremiumGames = {
	Tier = "Premium",
	PlaceIds = {
		Arsenal = 286090429,
		Rivals = 17625359962,
	},
}

function PremiumGames:GetName(placeId: number): string?
	for name, id in pairs(self.PlaceIds) do
		if id == placeId then return name end
	end
	return nil
end

function PremiumGames:IsSupported(placeId: number): boolean
	return self:GetName(placeId) ~= nil
end

return PremiumGames
