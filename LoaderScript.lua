--!strict
-- LoaderScript.lua - entry buat animula hub (premium / free / info)
-- ini file SATU SATUNYA yang di push ke https://github.com/AnimulaOffcial/Script
-- jadi semua ui langsung di dalem sini, gak include LoaderUI lagi biar gampang loadstring

-- gw bikin ui nya mirip animula biru hydro archon, tapi standalone biar gak ribet
-- ada 3 tabs: premium, free, info

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local RunService         = game:GetService("RunService")
local LocalPlayer        = Players.LocalPlayer

-- supabase config (project animula)
local SUPABASE_URL  = "https://eiykqbkfljqxwfqdffpo.supabase.co"
local SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpeWtxYmtmbGpxeHdmcWRmZnBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4Mzg0NDIsImV4cCI6MjEwMzQxNDQ0Mn0.54QPoPN3LdV4gEqjEZydpI-bd3JZ_G9RZwlJIlxz3v4"

-- tema biru animula - copy dari animula theme biar konsisten
local T = {
    bg          = Color3.fromRGB(13,  20,  38),
    surface     = Color3.fromRGB(19,  30,  58),
    surface2    = Color3.fromRGB(26,  42,  78),
    surfaceHover= Color3.fromRGB(33,  52,  96),
    primary     = Color3.fromRGB(77,  163, 255),
    primaryDark = Color3.fromRGB(42,  119, 217),
    secondary   = Color3.fromRGB(91,  202, 255),
    accent      = Color3.fromRGB(155, 214, 255),
    gold        = Color3.fromRGB(214, 196, 135),
    text        = Color3.fromRGB(235, 245, 255),
    dim         = Color3.fromRGB(155, 175, 205),
    muted       = Color3.fromRGB(105, 125, 158),
    border      = Color3.fromRGB(42,  64,  112),
    success     = Color3.fromRGB(74,  222, 128),
    warning     = Color3.fromRGB(251, 191, 36),
    error       = Color3.fromRGB(248, 113, 113),
}

local function getHui(): Instance
    local ok, hui = pcall(function() return (gethui and gethui()) end)
    if ok and typeof(hui) == "Instance" then return hui end
    if RunService:IsStudio() then
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then return cg end
    end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or workspace :: any
end

local function corner(p: Instance, r: UDim)
    local c = Instance.new("UICorner")
    c.CornerRadius = r
    c.Parent = p
    return c
end

local function stroke(p: Instance, col: Color3, thick: number?, trans: number?)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function pad(p: Instance, l: number, t: number, r: number, b: number)
    local x = Instance.new("UIPadding")
    x.PaddingLeft = UDim.new(0,l); x.PaddingTop=UDim.new(0,t); x.PaddingRight=UDim.new(0,r); x.PaddingBottom=UDim.new(0,b)
    x.Parent=p; return x
end

local function tween(obj: Instance, props: {}, time: number?)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end

local function gradient(p: Instance, c1: Color3, c2: Color3, rot: number?)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1,c2); g.Rotation = rot or 90; g.Parent=p; return g
end

-- supabase: cek & redeem key (bind ke roblox UserId) — anti bobol via RPC
local function checkPremiumKey(key: string): (boolean, string)
    return checkKeyViaRpc(key)
end

local function checkKeyViaRpc(key: string): (boolean, string)
    if key == "" then return false, "key kosong" end
    if not string.match(key, "^Animula%-(pk|fk)%-[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]") then
        -- quick reject biar gak spam supabase
        if #key < 10 then return false, "key kosong" end
    end
    local fn: any = (request or http_request or (syn and syn.request) or (http and http.request))
    if fn then
        local ok, res = pcall(function()
            return fn({
                Url = SUPABASE_URL .. "/rest/v1/rpc/animula_check_key",
                Method = "POST",
                Headers = {
                    ["apikey"] = SUPABASE_ANON,
                    ["Authorization"] = "Bearer " .. SUPABASE_ANON,
                    ["Content-Type"] = "application/json",
                },
                Body = HttpService:JSONEncode({ p_key = key }),
            })
        end)
        if ok and res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 then
            local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if ok2 and data then
                if data.ok then
                    local dl: string = if data.days_left == nil then "unlimited" else tostring(data.days_left) .. " hari"
                    return true, "valid (" .. dl .. ")"
                else
                    return false, data.error or "tidak valid"
                end
            end
        end
    end
    -- fallback: format local (biar gak hard depend) — tapi tetap cek prefix pk/fk 25
    if string.match(key, "^Animula%-(pk|fk)%-[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]") and #key >= 34 then
        return true, "valid (offline)"
    end
    return false, "gagal cek, cek internet / format key"
end

local function redeemKey(key: string): (boolean, string)
    local uid: number = LocalPlayer and LocalPlayer.UserId or 0
    local uname: string = LocalPlayer and LocalPlayer.Name or ""
    if uid <= 0 then return false, "userId tidak ketemu" end
    local fn: any = (request or http_request or (syn and syn.request) or (http and http.request))
    if not fn then return false, "executor tidak support http" end
    local ok, res = pcall(function()
        return fn({
            Url = SUPABASE_URL .. "/rest/v1/rpc/animula_redeem_key",
            Method = "POST",
            Headers = {
                ["apikey"] = SUPABASE_ANON,
                ["Authorization"] = "Bearer " .. SUPABASE_ANON,
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode({
                p_key = key,
                p_roblox_user_id = uid,
                p_roblox_username = uname,
                p_ip = "",
            }),
        })
    end)
    if ok and res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 then
        local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok2 and data then
            if data.ok then return true, data.message or "redeemed" else return false, data.error or "gagal redeem" end
        end
    end
    return false, "gagal redeem, cek internet"
end

-- load game script via http (raw github)
local function loadGameScript(gameName: string, tier: string)
    -- tier = Free / Premium
    local base = "https://raw.githubusercontent.com/AnimulaOffcial/Script/main/MenuScript/" .. tier .. "/Game/" .. gameName .. "/" .. gameName .. "Loader.lua"
    local ok, err = pcall(function()
        local code = game:HttpGet(base)
        if code and #code > 10 then
            loadstring(code)()
        else
            warn("[Animula] game script kosong: " .. gameName)
        end
    end)
    if not ok then
        warn("[Animula] gagal load " .. gameName .. ": " .. tostring(err))
    end
end

-- daftar game (sinkron sama folder MenuScript di repo, tapi kita hardcode biar gak scan)
local GAMES_FREE = {
    "AdoptMe","AllStarTowerDefense","AnimeAdventures","AnimeDimensions","AnimeVanguards",
    "Arsenal","BasketballZero","BedWars","BeeSwarmSimulator","BladeBall","BloxFruits",
    "BlueLockRivals","BreakIn","Brookhaven","BubbleGumSimulatorInfinity","BuildABoat",
    "DOORS","Fisch","Forsaken","GrowAGarden","Jailbreak","KingLegacy","MicUp",
    "MurderMystery2","NinjaLegends","PetSimulator99","PetSimulatorX","Piggy","Pressure",
    "Rivals","RoyaleHigh","ShindoLife","SolsRNG","StealABrainrot","StrongestBattlegrounds",
    "ToiletTowerDefense","TowerDefenseSimulator","TowerOfHell","UntitledBoxingGame","WelcomeToBloxburg",
}
local GAMES_PREMIUM = {
    "AdoptMe","AllStarTowerDefense","AnimeAdventures","AnimeDimensions","AnimeVanguards",
    "Arsenal","BasketballZero","BedWars","BeeSwarmSimulator","BladeBall","BloxFruits",
    "BlueLockRivals","BreakIn","Brookhaven","BubbleGumSimulatorInfinity","BuildABoat",
    "DOORS","Fisch","Forsaken","GrowAGarden","Jailbreak","KingLegacy","MicUp",
    "MurderMystery2","NinjaLegends","PetSimulator99","PetSimulatorX","Piggy","Pressure",
    "Rivals","RoyaleHigh","ShindoLife","SolsRNG","StealABrainrot","StrongestBattlegrounds",
    "ToiletTowerDefense","TowerDefenseSimulator","TowerOfHell","UntitledBoxingGame","WelcomeToBloxburg",
}

-- ============================================
--  UI
-- ============================================
local hui = getHui()

local sg = Instance.new("ScreenGui")
sg.Name = "AnimulaLoader"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 20
sg.Parent = hui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(560, 420)
main.Position = UDim2.fromScale(0.5,0.5)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.BackgroundColor3 = T.surface
main.Parent = sg
corner(main, UDim.new(0,16))
stroke(main, T.border, 1.5, 0.15)
main.ClipsDescendants = true

-- light biru tiap sudut (4 corner glow)
for _, pos in ipairs({
    UDim2.fromOffset(0,0),
    UDim2.new(1,-22,0,0),
    UDim2.fromOffset(0,398),
    UDim2.new(1,-22,1,-22),
}) do
    local glow = Instance.new("Frame")
    glow.BackgroundColor3 = T.primary
    glow.BackgroundTransparency = 0.75
    glow.Size = UDim2.fromOffset(22,22)
    glow.Position = pos
    glow.ZIndex = 10
    glow.BorderSizePixel = 0
    glow.Parent = main
    corner(glow, UDim.new(1,0))
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(ColorSequenceKeypoint.new(0, T.primary), ColorSequenceKeypoint.new(1, T.accent))
    g.Rotation = 45
    g.Parent = glow
    -- inner dot biar makin light
    local dot = Instance.new("Frame")
    dot.BackgroundColor3 = Color3.new(1,1,1)
    dot.BackgroundTransparency = 0.6
    dot.Size = UDim2.fromOffset(6,6)
    dot.Position = UDim2.fromScale(0.5,0.5)
    dot.AnchorPoint = Vector2.new(0.5,0.5)
    dot.Parent = glow
    corner(dot, UDim.new(1,0))
end

-- shadow
do
    local s = Instance.new("Frame")
    s.BackgroundColor3 = Color3.new(0,0,0)
    s.BackgroundTransparency = 0.78
    s.Size = UDim2.new(1,14,1,14); s.Position = UDim2.fromOffset(-7,-7)
    s.BorderSizePixel=0; s.ZIndex=0; s.Parent=main
    corner(s, UDim.new(0,18))
    main.ZIndex=2
end

-- accent bar
do
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = T.primary; bar.Size=UDim2.new(1,0,0,3)
    bar.BorderSizePixel=0; bar.ZIndex=5; bar.Parent=main
    corner(bar, UDim.new(0,99))
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(T.primary, T.gold); g.Rotation=0; g.Parent=bar
    local c = bar:FindFirstChildOfClass("UICorner") :: any
    if c then c.CornerRadius=UDim.new(0,16) end
end

-- title bar
local titleBar = Instance.new("Frame")
titleBar.BackgroundTransparency=1; titleBar.Size=UDim2.new(1,0,0,52)
titleBar.Position=UDim2.fromOffset(0,3); titleBar.ZIndex=3; titleBar.Parent=main

local iconWrap = Instance.new("Frame")
iconWrap.BackgroundColor3=T.primary; iconWrap.Size=UDim2.fromOffset(36,36)
iconWrap.Position=UDim2.fromOffset(14,8); iconWrap.Parent=titleBar
corner(iconWrap, UDim.new(1,0))
gradient(iconWrap, T.primary, T.secondary, 35)

local iconLbl = Instance.new("TextLabel")
iconLbl.BackgroundTransparency=1; iconLbl.Size=UDim2.fromScale(1,1)
iconLbl.Font=Enum.Font.GothamBold; iconLbl.TextSize=18; iconLbl.TextColor3=Color3.new(1,1,1)
iconLbl.Text="◈"; iconLbl.Parent=iconWrap

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency=1; titleLbl.Position=UDim2.fromOffset(58,6)
titleLbl.Size=UDim2.new(1,-120,0,20); titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=16
titleLbl.TextColor3=T.text; titleLbl.TextXAlignment=Enum.TextXAlignment.Left
titleLbl.Text="Animula Hub"; titleLbl.Parent=titleBar

local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency=1; subLbl.Position=UDim2.fromOffset(58,26)
subLbl.Size=UDim2.new(1,-120,0,14); subLbl.Font=Enum.Font.Gotham; subLbl.TextSize=11
subLbl.TextColor3=T.dim; subLbl.TextXAlignment=Enum.TextXAlignment.Left
subLbl.Text="v2.2  •  pilih Premium / Free"; subLbl.Parent=titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundColor3=T.surface2; closeBtn.Size=UDim2.fromOffset(28,28)
closeBtn.Position=UDim2.new(1,-36,0,10); closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=14
closeBtn.TextColor3=T.dim; closeBtn.Text="x"; closeBtn.AutoButtonColor=false; closeBtn.Parent=titleBar
corner(closeBtn, UDim.new(0,8)); stroke(closeBtn, T.border, 1, 0.5)
closeBtn.MouseButton1Click:Connect(function()
    tween(main, {BackgroundTransparency=1}, 0.18)
    task.wait(0.18); sg:Destroy()
end)

-- tab bar (3 tabs)
local tabBar = Instance.new("Frame")
tabBar.BackgroundTransparency=1; tabBar.Size=UDim2.new(1,-16,0,36)
tabBar.Position=UDim2.fromOffset(8,52); tabBar.Parent=main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.Padding=UDim.new(0,6); tabLayout.Parent=tabBar

local pages: { [string]: Frame } = {}
local tabBtns: { [string]: TextButton } = {}

local body = Instance.new("Frame")
body.BackgroundTransparency=1; body.Size=UDim2.new(1,-16,1,-96)
body.Position=UDim2.fromOffset(8,92); body.Parent=main

-- helper: notif kecil di dalam loader
local function notify(title: string, desc: string, ok: boolean?)
    local n = Instance.new("Frame")
    n.BackgroundColor3 = if ok == false then Color3.fromRGB(60,30,35) else T.surface2
    n.Size=UDim2.new(1,-12,0,44); n.Position=UDim2.new(0,6,1,-50)
    n.BorderSizePixel=0; n.ZIndex=20; n.Parent=body
    corner(n, UDim.new(0,10)); stroke(n, if ok==false then T.error else T.border, 1, 0.4)
    pad(n,10,8,10,8)
    local a = Instance.new("TextLabel")
    a.BackgroundTransparency=1; a.Size=UDim2.new(1,0,0,16); a.Font=Enum.Font.GothamBold; a.TextSize=12
    a.TextColor3=if ok==false then T.error else T.text; a.TextXAlignment=Enum.TextXAlignment.Left
    a.Text=title; a.Parent=n
    local b = Instance.new("TextLabel")
    b.BackgroundTransparency=1; b.Position=UDim2.fromOffset(0,16); b.Size=UDim2.new(1,0,0,14)
    b.Font=Enum.Font.Gotham; b.TextSize=11; b.TextColor3=T.dim; b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextWrapped=true; b.Text=desc; b.Parent=n
    tween(n, {BackgroundTransparency=0}, 0.15)
    task.delay(2.5, function()
        if n.Parent then tween(n,{BackgroundTransparency=1},0.2); task.wait(0.2); n:Destroy() end
    end)
end

-- buat page
local function makePage(name: string): Frame
    local f = Instance.new("Frame")
    f.Name=name; f.BackgroundTransparency=1; f.Size=UDim2.fromScale(1,1); f.Visible=false; f.Parent=body
    local sc = Instance.new("ScrollingFrame")
    sc.Name="Scroll"; sc.BackgroundTransparency=1; sc.Size=UDim2.fromScale(1,1)
    sc.CanvasSize=UDim2.fromOffset(0,0); sc.ScrollBarThickness=2; sc.ScrollBarImageColor3=T.primary
    sc.BorderSizePixel=0; sc.Parent=f
    pad(sc, 4,6,4,6)
    local list = Instance.new("UIListLayout")
    list.FillDirection=Enum.FillDirection.Vertical; list.Padding=UDim.new(0,8); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=sc
    -- auto canvas
    local function refresh()
        task.defer(function()
            if not sc.Parent then return end
            local sz = list.AbsoluteContentSize
            sc.CanvasSize = UDim2.fromOffset(0, sz.Y + 16)
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
    task.defer(refresh)
    pages[name]=f
    -- simpen sc biar bisa add
    f:SetAttribute("Scroll", sc.Name)
    return f
end

local function getScroll(page: Frame): ScrollingFrame
    return page:FindFirstChild("Scroll") :: ScrollingFrame
end

local function switchTab(name: string)
    for k, f in pairs(pages) do f.Visible = (k==name) end
    for k, b in pairs(tabBtns) do
        b.BackgroundColor3 = if k==name then T.primary else T.surface2
        b.TextColor3 = if k==name then Color3.new(1,1,1) else T.dim
        local st = b:FindFirstChildOfClass("UIStroke") :: any
        if st then st.Color = if k==name then T.primary else T.border end
    end
end

-- tab buttons
for _, info in ipairs({
    {key="Premium", label="◈ Premium"},
    {key="Free",    label="◇ Free"},
    {key="Info",    label="ℹ Info"},
}) do
    local b = Instance.new("TextButton")
    b.Name=info.key; b.BackgroundColor3=T.surface2; b.Size=UDim2.new(0.33,-4,1,0)
    b.Font=Enum.Font.GothamSemibold; b.TextSize=12; b.TextColor3=T.dim
    b.Text=info.label; b.AutoButtonColor=false; b.Parent=tabBar
    corner(b, UDim.new(0,8)); stroke(b, T.border, 1, 0.5)
    tabBtns[info.key]=b
    b.MouseButton1Click:Connect(function() switchTab(info.key) end)
end

-- ============================================
--  TAB: PREMIUM
-- ============================================
local premiumPage = makePage("Premium")
do
    local sc = getScroll(premiumPage)

    -- keys input
    local card = Instance.new("Frame")
    card.BackgroundColor3=T.surface2; card.Size=UDim2.new(1,0,0,78); card.Parent=sc
    corner(card, UDim.new(0,10)); stroke(card, T.border, 1, 0.35); pad(card,10,8,10,8)

    local l1 = Instance.new("TextLabel")
    l1.BackgroundTransparency=1; l1.Size=UDim2.new(1,0,0,14); l1.Font=Enum.Font.GothamBold; l1.TextSize=12
    l1.TextColor3=T.text; l1.TextXAlignment=Enum.TextXAlignment.Left; l1.Text="Premium Keys"; l1.Parent=card

    local l2 = Instance.new("TextLabel")
    l2.BackgroundTransparency=1; l2.Position=UDim2.fromOffset(0,16); l2.Size=UDim2.new(1,0,0,12)
    l2.Font=Enum.Font.Gotham; l2.TextSize=10; l2.TextColor3=T.muted; l2.TextXAlignment=Enum.TextXAlignment.Left
    l2.Text="masukin key premium, nanti di cek ke supabase"; l2.Parent=card

    local keyBox = Instance.new("TextBox")
    keyBox.BackgroundColor3=T.bg; keyBox.Size=UDim2.new(1,-88,0,28); keyBox.Position=UDim2.fromOffset(0,34)
    keyBox.Font=Enum.Font.Gotham; keyBox.TextSize=12; keyBox.TextColor3=T.text
    keyBox.PlaceholderText="ANIMULA-XXXX-XXXX"; keyBox.PlaceholderColor3=T.muted
    keyBox.Text=""; keyBox.ClearTextOnFocus=false; keyBox.Parent=card
    corner(keyBox, UDim.new(0,8)); stroke(keyBox, T.border, 1, 0.4); pad(keyBox,8,0,8,0)

    local checkBtn = Instance.new("TextButton")
    checkBtn.BackgroundColor3=T.primary; checkBtn.Size=UDim2.fromOffset(80,28); checkBtn.Position=UDim2.new(1,-80,0,34)
    checkBtn.Font=Enum.Font.GothamBold; checkBtn.TextSize=11; checkBtn.TextColor3=Color3.new(1,1,1)
    checkBtn.Text="Check"; checkBtn.AutoButtonColor=false; checkBtn.Parent=card
    corner(checkBtn, UDim.new(0,8))
    local g = Instance.new("UIGradient"); g.Color=ColorSequence.new(T.primary, T.primaryDark); g.Rotation=90; g.Parent=checkBtn

    -- status
    local statusLbl = Instance.new("TextLabel")
    statusLbl.BackgroundTransparency=1; statusLbl.Size=UDim2.new(1,0,0,14); statusLbl.Font=Enum.Font.Gotham; statusLbl.TextSize=10
    statusLbl.TextColor3=T.dim; statusLbl.TextXAlignment=Enum.TextXAlignment.Left; statusLbl.Text=""; statusLbl.Parent=sc

    local premiumUnlocked = false
    local selectedGamePremium: string? = nil
    local gameButtons: { [string]: TextButton } = {}

    -- game list (scroll, hidden until key valid)
    local gameWrap = Instance.new("Frame")
    gameWrap.BackgroundTransparency=1; gameWrap.Size=UDim2.new(1,0,0,0); gameWrap.AutomaticSize=Enum.AutomaticSize.Y
    gameWrap.Visible=false; gameWrap.Parent=sc
    local glist = Instance.new("UIListLayout")
    glist.FillDirection=Enum.FillDirection.Vertical; glist.Padding=UDim.new(0,6); glist.SortOrder=Enum.SortOrder.LayoutOrder; glist.Parent=gameWrap

    local gameTitle = Instance.new("TextLabel")
    gameTitle.BackgroundTransparency=1; gameTitle.Size=UDim2.new(1,0,0,14); gameTitle.Font=Enum.Font.GothamBold; gameTitle.TextSize=12
    gameTitle.TextColor3=T.text; gameTitle.TextXAlignment=Enum.TextXAlignment.Left; gameTitle.Text="Pilih Game Premium"; gameTitle.Parent=gameWrap

    local gameGrid = Instance.new("Frame")
    gameGrid.BackgroundTransparency=1; gameGrid.Size=UDim2.new(1,0,0,0); gameGrid.AutomaticSize=Enum.AutomaticSize.Y; gameGrid.Parent=gameWrap
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize=UDim2.fromOffset(152,30); gridLayout.CellPadding=UDim2.fromOffset(6,6)
    gridLayout.FillDirectionMaxCells=3; gridLayout.SortOrder=Enum.SortOrder.LayoutOrder; gridLayout.Parent=gameGrid

    for _, gname in ipairs(GAMES_PREMIUM) do
        local b = Instance.new("TextButton")
        b.Name=gname; b.BackgroundColor3=T.surface; b.Font=Enum.Font.Gotham; b.TextSize=11
        b.TextColor3=T.dim; b.Text=gname; b.AutoButtonColor=false; b.Parent=gameGrid
        corner(b, UDim.new(0,8)); stroke(b, T.border, 1, 0.35)
        b.MouseEnter:Connect(function() if selectedGamePremium~=gname then tween(b,{BackgroundColor3=T.surfaceHover},0.12) end end)
        b.MouseLeave:Connect(function() if selectedGamePremium~=gname then tween(b,{BackgroundColor3=T.surface},0.12) end end)
        b.MouseButton1Click:Connect(function()
            selectedGamePremium=gname
            for n, btn in pairs(gameButtons) do
                btn.BackgroundColor3 = if n==gname then T.primary else T.surface
                btn.TextColor3 = if n==gname then Color3.new(1,1,1) else T.dim
            end
        end)
        gameButtons[gname]=b
    end

    local loadBtn = Instance.new("TextButton")
    loadBtn.BackgroundColor3=T.primary; loadBtn.Size=UDim2.new(1,0,0,32); loadBtn.Font=Enum.Font.GothamBold; loadBtn.TextSize=12
    loadBtn.TextColor3=Color3.new(1,1,1); loadBtn.Text="Load Premium Script  ▶"; loadBtn.AutoButtonColor=false; loadBtn.Parent=gameWrap
    corner(loadBtn, UDim.new(0,8))
    local lg = Instance.new("UIGradient"); lg.Color=ColorSequence.new(T.primary, T.secondary); lg.Rotation=0; lg.Parent=loadBtn

    checkBtn.MouseButton1Click:Connect(function()
        local key = keyBox.Text
        statusLbl.Text = "ngecek..."
        statusLbl.TextColor3 = T.dim
        tween(keyBox:FindFirstChildOfClass("UIStroke") :: any, {Color=T.primary}, 0.15)
        task.wait(0.1)
        -- redeem dulu (bind ke roblox UserId) — baru cek
        local okR, msgR = redeemKey(key)
        if okR then
            premiumUnlocked = true
            statusLbl.Text = "✓ " .. msgR
            statusLbl.TextColor3 = T.success
            gameWrap.Visible = true
            tween(checkBtn, {BackgroundColor3=T.success}, 0.2)
            checkBtn.Text = "Valid ✓"
            notify("Keys valid", "premium kebuka, pilih game lalu load", true)
        else
            -- kalau sudah redeemed by you, check aja masih valid?
            local ok, msg = checkPremiumKey(key)
            if ok and string.find(msgR, "already redeemed") then
                premiumUnlocked = true
                statusLbl.Text = "✓ " .. msg
                statusLbl.TextColor3 = T.success
                gameWrap.Visible = true
                checkBtn.Text = "Valid ✓"
                notify("Keys valid", "welcome back", true)
            else
                premiumUnlocked = false
                statusLbl.Text = "✗ " .. msgR
                statusLbl.TextColor3 = T.error
                gameWrap.Visible = false
                tween(keyBox:FindFirstChildOfClass("UIStroke") :: any, {Color=T.error}, 0.15)
                notify("Keys salah", msgR, false)
            end
        end
    end)

    loadBtn.MouseButton1Click:Connect(function()
        if not premiumUnlocked then notify("Keys belum valid", "check keys dulu", false); return end
        if not selectedGamePremium then notify("Pilih game dulu", "klik salah satu game premium", false); return end
        -- double-check masih valid sebelum load (anti time warp)
        local ok, msg = checkPremiumKey(keyBox.Text)
        if not ok then notify("Key expired", msg, false); return end
        notify("Loading Premium", selectedGamePremium .. " ...", true)
        sg:Destroy()
        loadGameScript(selectedGamePremium, "Premium")
    end)
end

-- ============================================
--  TAB: FREE
-- ============================================
local freePage = makePage("Free")
do
    local sc = getScroll(freePage)

    local card = Instance.new("Frame")
    card.BackgroundColor3=T.surface2; card.Size=UDim2.new(1,0,0,52); card.Parent=sc
    corner(card, UDim.new(0,10)); stroke(card, T.border, 1, 0.35); pad(card,10,8,10,8)

    local t1 = Instance.new("TextLabel")
    t1.BackgroundTransparency=1; t1.Size=UDim2.new(1,-90,0,14); t1.Font=Enum.Font.GothamBold; t1.TextSize=12
    t1.TextColor3=T.text; t1.TextXAlignment=Enum.TextXAlignment.Left; t1.Text="Free Hub"; t1.Parent=card
    local t2 = Instance.new("TextLabel")
    t2.BackgroundTransparency=1; t2.Position=UDim2.fromOffset(0,16); t2.Size=UDim2.new(1,-90,0,12)
    t2.Font=Enum.Font.Gotham; t2.TextSize=10; t2.TextColor3=T.muted; t2.TextXAlignment=Enum.TextXAlignment.Left
    t2.Text="langsung confirm, gak perlu keys"; t2.Parent=card

    local confirmedFree = false
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.BackgroundColor3=T.surface; confirmBtn.Size=UDim2.fromOffset(80,28); confirmBtn.Position=UDim2.new(1,-80,0.5,-14)
    confirmBtn.Font=Enum.Font.GothamBold; confirmBtn.TextSize=11; confirmBtn.TextColor3=T.dim
    confirmBtn.Text="Confirm"; confirmBtn.AutoButtonColor=false; confirmBtn.Parent=card
    corner(confirmBtn, UDim.new(0,8)); stroke(confirmBtn, T.border, 1, 0.4)

    local gameWrapFree = Instance.new("Frame")
    gameWrapFree.BackgroundTransparency=1; gameWrapFree.Size=UDim2.new(1,0,0,0); gameWrapFree.AutomaticSize=Enum.AutomaticSize.Y
    gameWrapFree.Visible=false; gameWrapFree.Parent=sc
    local gl = Instance.new("UIListLayout")
    gl.FillDirection=Enum.FillDirection.Vertical; gl.Padding=UDim.new(0,6); gl.Parent=gameWrapFree

    local gt = Instance.new("TextLabel")
    gt.BackgroundTransparency=1; gt.Size=UDim2.new(1,0,0,14); gt.Font=Enum.Font.GothamBold; gt.TextSize=12
    gt.TextColor3=T.text; gt.TextXAlignment=Enum.TextXAlignment.Left; gt.Text="Pilih Game Free"; gt.Parent=gameWrapFree

    local grid = Instance.new("Frame")
    grid.BackgroundTransparency=1; grid.Size=UDim2.new(1,0,0,0); grid.AutomaticSize=Enum.AutomaticSize.Y; grid.Parent=gameWrapFree
    local grLayout = Instance.new("UIGridLayout")
    grLayout.CellSize=UDim2.fromOffset(152,30); grLayout.CellPadding=UDim2.fromOffset(6,6)
    grLayout.FillDirectionMaxCells=3; grLayout.SortOrder=Enum.SortOrder.LayoutOrder; grLayout.Parent=grid

    local selectedFree: string? = nil
    local freeBtns: { [string]: TextButton } = {}

    for _, gname in ipairs(GAMES_FREE) do
        local b = Instance.new("TextButton")
        b.Name=gname; b.BackgroundColor3=T.surface; b.Font=Enum.Font.Gotham; b.TextSize=11
        b.TextColor3=T.dim; b.Text=gname; b.AutoButtonColor=false; b.Parent=grid
        corner(b, UDim.new(0,8)); stroke(b, T.border, 1, 0.35)
        b.MouseButton1Click:Connect(function()
            selectedFree=gname
            for n, btn in pairs(freeBtns) do
                btn.BackgroundColor3 = if n==gname then T.primary else T.surface
                btn.TextColor3 = if n==gname then Color3.new(1,1,1) else T.dim
            end
        end)
        freeBtns[gname]=b
    end

    local loadFree = Instance.new("TextButton")
    loadFree.BackgroundColor3=T.primary; loadFree.Size=UDim2.new(1,0,0,32); loadFree.Font=Enum.Font.GothamBold; loadFree.TextSize=12
    loadFree.TextColor3=Color3.new(1,1,1); loadFree.Text="Load Free Script  ▶"; loadFree.AutoButtonColor=false; loadFree.Parent=gameWrapFree
    corner(loadFree, UDim.new(0,8))
    local lg2 = Instance.new("UIGradient"); lg2.Color=ColorSequence.new(T.primary, T.secondary); lg2.Rotation=0; lg2.Parent=loadFree

    confirmBtn.MouseButton1Click:Connect(function()
        confirmedFree = not confirmedFree
        confirmBtn.BackgroundColor3 = if confirmedFree then T.success else T.surface
        confirmBtn.TextColor3 = if confirmedFree then Color3.new(1,1,1) else T.dim
        confirmBtn.Text = if confirmedFree then "Confirmed ✓" else "Confirm"
        gameWrapFree.Visible = confirmedFree
        if confirmedFree then notify("Free confirmed", "pilih game lalu load", true) end
    end)

    loadFree.MouseButton1Click:Connect(function()
        if not confirmedFree then notify("Confirm dulu", "klik confirm di atas", false); return end
        if not selectedFree then notify("Pilih game dulu", "klik salah satu game free", false); return end
        sg:Destroy()
        loadGameScript(selectedFree, "Free")
    end)
end

-- ============================================
--  TAB: INFO
-- ============================================
local infoPage = makePage("Info")
do
    local sc = getScroll(infoPage)

    local function infoCard(title: string, desc: string)
        local c = Instance.new("Frame")
        c.BackgroundColor3=T.surface2; c.Size=UDim2.new(1,0,0,52); c.AutomaticSize=Enum.AutomaticSize.Y; c.Parent=sc
        corner(c, UDim.new(0,10)); stroke(c, T.border, 1, 0.32); pad(c,10,8,10,8)
        local a = Instance.new("TextLabel")
        a.BackgroundTransparency=1; a.Size=UDim2.new(1,0,0,14); a.Font=Enum.Font.GothamBold; a.TextSize=12
        a.TextColor3=T.text; a.TextXAlignment=Enum.TextXAlignment.Left; a.Text=title; a.Parent=c
        local b = Instance.new("TextLabel")
        b.BackgroundTransparency=1; b.Position=UDim2.fromOffset(0,16); b.Size=UDim2.new(1,0,0,14)
        b.AutomaticSize=Enum.AutomaticSize.Y; b.Font=Enum.Font.Gotham; b.TextSize=11
        b.TextColor3=T.dim; b.TextXAlignment=Enum.TextXAlignment.Left; b.TextWrapped=true; b.Text=desc; b.Parent=c
        task.defer(function() c.Size = UDim2.new(1,0,0, b.TextBounds.Y + 28) end)
        return c
    end

    infoCard("Animula Hub v2.2", "Premium = keys via Supabase, Free = confirm lalu load. UI biru hydro archon.")
    infoCard("Executor", 'loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/Script/main/LoaderScript.lua"))()')
    infoCard("UI", 'loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/UI/main/LoaderUI.lua"))()  •  4449 lines bundled, no script.Parent')
    infoCard("Support", "DM di discord kalo keys premium bermasalah")

    local discordBtn = Instance.new("TextButton")
    discordBtn.BackgroundColor3=T.primary; discordBtn.Size=UDim2.new(1,0,0,30); discordBtn.Font=Enum.Font.GothamBold; discordBtn.TextSize=11
    discordBtn.TextColor3=Color3.new(1,1,1); discordBtn.Text="Copy Discord Invite"; discordBtn.AutoButtonColor=false; discordBtn.Parent=sc
    corner(discordBtn, UDim.new(0,8))
    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard("https://discord.gg/animula") end
        notify("Copied", "discord invite ke clipboard", true)
    end)
end

-- draggable
do
    local dragging=false; local start=Vector2.zero; local startPos=main.Position
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; start=Vector2.new(i.Position.X, i.Position.Y); startPos=main.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = Vector2.new(i.Position.X, i.Position.Y) - start
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- toggle key
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- entrance
main.Size = UDim2.fromOffset(540, 400)
tween(main, {Size=UDim2.fromOffset(560,420)}, 0.32, Enum.EasingStyle.Back)
main.BackgroundTransparency=0.15
tween(main, {BackgroundTransparency=0}, 0.22)

-- default tab
switchTab("Premium")
print("[Animula Loader] ready - Premium / Free / Info")
