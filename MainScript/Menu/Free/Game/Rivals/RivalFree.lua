--!strict
-- Free Rivals entry: opens the shared BigUI interface only.

local EXPECTED_PLACE_ID = 17625359962
local BIG_UI_URL = "https://raw.githubusercontent.com/AnimulaOffcial/UI/main/MainUI/BigUI/LoaderBigUI.lua"

if game.PlaceId ~= EXPECTED_PLACE_ID then
	warn("[Animula] Rivals UI is only available in Rivals.")
	return
end

local loaded, BigUI = pcall(function()
	return loadstring(game:HttpGet(BIG_UI_URL))()
end)
if not loaded or type(BigUI) ~= "table" then
	warn("[Animula] BigUI could not be loaded.")
	return
end

local window = BigUI:MakeWindow({
	Name = "Rivals",
	SubTitle = "Free access",
	Theme = "AnimulaDark",
	Draggable = true,
})
local status = window:MakeTab({ Name = "Status", Icon = "R", Default = true })
status:AddParagraph("Rivals Free", "The BigUI interface is ready for this game.")
status:AddButton({
	Name = "Close interface",
	Desc = "Close the Rivals interface.",
	ButtonText = "Close",
	Callback = function() window:Destroy() end,
})

return window
