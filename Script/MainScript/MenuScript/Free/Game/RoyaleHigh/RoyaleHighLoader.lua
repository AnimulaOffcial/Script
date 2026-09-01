-- GAME MODULE: RoyaleHigh  [tier: Free]
-- Detection: PlaceIds = { 735030788 } | nameKeys = { "royale high" }
-- REAL SYSTEMS (verified): Campus, Diamonds, Classes, Dorms
--
-- PROMPT FITUR RoyaleHigh (buat fitur dari sistem nyata game ini, JANGAN invent):
--   - Teleport antar campus & class
--   - Diamond farm (via UI tombol)
--   - Fly & no-clip dalam map
--   Cara aman: pakai Toolkit (WalkSpeed/Fly/Noclip/Teleport/ESP/Server) +
--   hubungkan ke sistem di atas lewat cara terverifikasi. JANGAN buat fitur
--   yang tidak ada di RoyaleHigh.
local placeIds = { 735030788 }
local nameKeys = { "royale high" }

local function IsThisGame()
    if table.find(placeIds, game.PlaceId) then return true end
    local ok, nm = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:lower()
    end)
    if ok and nm then
        for _, k in ipairs(nameKeys) do
            if nm:find(k) then return true end
        end
    end
    return false
end

if IsThisGame() then
    return function(Animula, Window, Toolkit)
        local Tab = Window:MakeTab({ Name = "RoyaleHigh", Icon = "rbxassetid://4483345998" })

        Tab:AddSection({ Name = "RoyaleHigh — Free" })
        Tab:AddParagraph("RoyaleHigh", "PlaceId: " .. tostring(game.PlaceId))
        Tab:AddButton({
            Name = "Copy PlaceId",
            Callback = function()
                pcall(function() if setclipboard then setclipboard(tostring(game.PlaceId)) end end)
                Animula:MakeNotification({ Name = "Copied", Content = "PlaceId: " .. tostring(game.PlaceId), Time = 2 })
            end,
        })

        Tab:AddSection({ Name = "About this game" })
        Tab:AddParagraph("Real systems", "Campus, Diamonds, Classes, Dorms")

        Tab:AddSection({ Name = "Character" })
        Tab:AddSlider({ Name = "WalkSpeed", Min = 0, Max = 500, Default = 16, Increment = 1, ValueName = "speed", Callback = Toolkit.SetWalkSpeed })
        Tab:AddSlider({ Name = "JumpPower", Min = 0, Max = 500, Default = 50, Increment = 1, ValueName = "power", Callback = Toolkit.SetJumpPower })
        Tab:AddSlider({ Name = "HipHeight", Min = 0, Max = 100, Default = 2, Increment = 0.5, ValueName = "hip", Callback = Toolkit.SetHipHeight })
        Tab:AddToggle({ Name = "Infinite Jump", Default = false, Callback = Toolkit.SetInfiniteJump })
        Tab:AddToggle({ Name = "Noclip", Default = false, Callback = Toolkit.SetNoclip })
        Tab:AddToggle({ Name = "Fly", Default = false, Callback = Toolkit.SetFly })
        Tab:AddSlider({ Name = "Fly Speed", Min = 10, Max = 200, Default = 60, Increment = 5, ValueName = "spd", Callback = Toolkit.SetFlySpeed })

        Tab:AddSection({ Name = "World" })
        Tab:AddDropdown({ Name = "Select Player", Default = Toolkit.GetPlayers()[1], Options = Toolkit.GetPlayers(), Callback = Toolkit.SetSelectedPlayer })
        Tab:AddButton({ Name = "Teleport to Player", Callback = function() Toolkit.TeleportToPlayer() end })
        Tab:AddToggle({ Name = "ESP Players", Default = false, Callback = Toolkit.SetESP })
        Tab:AddToggle({ Name = "Click Teleport", Default = false, Callback = Toolkit.SetClickTP })
        Tab:AddToggle({ Name = "Spin", Default = false, Callback = Toolkit.SetSpin })
        Tab:AddToggle({ Name = "FullBright", Default = false, Callback = Toolkit.SetFullBright })

        Tab:AddSection({ Name = "Server" })
        Tab:AddButton({ Name = "Copy JobId", Callback = Toolkit.CopyJob })
        Tab:AddButton({ Name = "Rejoin Server", Callback = Toolkit.Rejoin })
        Tab:AddButton({ Name = "New Server", Callback = Toolkit.NewServer })
    end
end

return nil

-- TEMPLATE - add a REAL feature (replace with verified game logic for RoyaleHigh):
-- Tab:AddToggle({ Name = "Real Feature", Default = false, Callback = function(v)
--     -- TODO: hubungkan ke sistem nyata RoyaleHigh (lihat PROMPT di atas)
--     Toolkit.SetWalkSpeed(v and 100 or 16)
-- end })
