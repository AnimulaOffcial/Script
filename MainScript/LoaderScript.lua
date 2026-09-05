--!strict
-- ANIMULA HUB - standalone loader interface
-- The runtime UI is fully self-contained in this file.
-- execute: loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/Script/main/MainScript/LoaderScript.lua"))()
-- tabs: Premium / Freemium / Free / Info

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- tema hydro archon (biru furina)
local T = {
	bg = Color3.fromRGB(8, 13, 31),
	surface = Color3.fromRGB(15, 25, 54),
	surface2 = Color3.fromRGB(23, 39, 79),
	surfaceHover = Color3.fromRGB(34, 59, 111),
	primary = Color3.fromRGB(74, 145, 255),
	primaryDark = Color3.fromRGB(49, 89, 202),
	secondary = Color3.fromRGB(106, 208, 255),
	accent = Color3.fromRGB(180, 228, 255),
	gold = Color3.fromRGB(232, 207, 146),
	text = Color3.fromRGB(241, 247, 255),
	dim = Color3.fromRGB(174, 196, 229),
	muted = Color3.fromRGB(132, 153, 192),
	border = Color3.fromRGB(47, 78, 143),
	borderLight = Color3.fromRGB(79, 119, 190),
	success = Color3.fromRGB(74, 222, 128),
	warning = Color3.fromRGB(251, 191, 36),
	error = Color3.fromRGB(248, 113, 113),
}

-- helpers
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
	x.PaddingLeft = UDim.new(0, l)
	x.PaddingTop = UDim.new(0, t)
	x.PaddingRight = UDim.new(0, r)
	x.PaddingBottom = UDim.new(0, b)
	x.Parent = p
	return x
end

local activeTweens: { [Instance]: Tween } = {}
local function tween(obj: Instance, props: { [string]: any }, time: number?, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local old = activeTweens[obj]
	if old then pcall(function() old:Cancel() end) end
	local tw = TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	activeTweens[obj] = tw
	tw.Completed:Connect(function()
		if activeTweens[obj] == tw then activeTweens[obj] = nil end
	end)
	tw:Play()
	return tw
end

local function gradient(p: Instance, c1: Color3, c2: Color3, rot: number?)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rot or 90
	g.Parent = p
	return g
end

local function gradient3(p: Instance, c1: Color3, c2: Color3, c3: Color3, rot: number?)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.5, c2),
		ColorSequenceKeypoint.new(1, c3),
	})
	g.Rotation = rot or 90
	g.Parent = p
	return g
end

local function ripple(btn: GuiObject, color: Color3?)
	local c = color or Color3.new(1, 1, 1)
	btn.ClipsDescendants = true
	btn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local r = Instance.new("Frame")
		r.BackgroundColor3 = c
		r.BackgroundTransparency = 0.7
		r.AnchorPoint = Vector2.new(0.5, 0.5)
		r.Position = UDim2.fromOffset(input.Position.X - btn.AbsolutePosition.X, input.Position.Y - btn.AbsolutePosition.Y)
		r.Size = UDim2.fromOffset(0, 0)
		r.ZIndex = btn.ZIndex + 1
		r.BorderSizePixel = 0
		r.Parent = btn
		corner(r, UDim.new(1, 0))
		local tw = TweenService:Create(r, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(300, 300),
			BackgroundTransparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() r:Destroy() end)
	end)
end

local function shimmerLoop(parent: GuiObject, cornerRadius: UDim, interval: number?)
	local sf = Instance.new("Frame")
	sf.Name = "Shimmer"
	sf.BackgroundColor3 = Color3.new(1, 1, 1)
	sf.BackgroundTransparency = 1
	sf.Size = UDim2.fromScale(1, 1)
	sf.BorderSizePixel = 0
	sf.ZIndex = parent.ZIndex + 1
	sf.Parent = parent
	corner(sf, cornerRadius)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.new(1, 1, 1))
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 0.5),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.55, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1, 0)
	g.Parent = sf
	task.spawn(function()
		while g.Parent do
			local tw = TweenService:Create(g, TweenInfo.new(1.8, Enum.EasingStyle.Linear), { Offset = Vector2.new(1, 0) })
			tw:Play()
			tw.Completed:Wait()
			if not g.Parent then break end
			g.Offset = Vector2.new(-1, 0)
			task.wait(interval or 1.5)
		end
	end)
	return sf
end

local function hoverGlow(obj: GuiObject, normalBg: Color3, strokeObj: UIStroke?, normalStroke: Color3, hoverStroke: Color3)
	obj.MouseEnter:Connect(function()
		tween(obj, { BackgroundColor3 = T.surfaceHover }, 0.12)
		if strokeObj then tween(strokeObj, { Color = hoverStroke }, 0.12) end
	end)
	obj.MouseLeave:Connect(function()
		tween(obj, { BackgroundColor3 = normalBg }, 0.12)
		if strokeObj then tween(strokeObj, { Color = normalStroke }, 0.12) end
	end)
end

-- Key binding happens only through ServerScriptService. The server verifies
-- Player.UserId and authenticates to the website with a Roblox Secret Store
-- value; clients never call Supabase or submit an identity directly.
local function redeemKey(key: string): (boolean, string, string?)
	local suffix = string.sub(key, -25)
	if #key ~= 36
		or string.match(key, "^Animula%-[pf]k%-[A-Za-z0-9]+$") == nil
		or string.match(suffix, "[A-Z]") == nil
		or string.match(suffix, "[a-z]") == nil
		or string.match(suffix, "[0-9]") == nil then
		return false, "Enter a valid Animula key.", nil
	end
	local broker = ReplicatedStorage:FindFirstChild("AnimulaKeyBroker")
	if not broker or not broker:IsA("RemoteFunction") then
		return false, "Secure key verification is not enabled for this experience.", nil
	end
	local invoked, data = pcall(function()
		return broker:InvokeServer(key)
	end)
	if not invoked or type(data) ~= "table" then
		return false, "Secure key verification is unavailable.", nil
	end
	if data.ok == true and (data.key_type == "pk" or data.key_type == "fk") then
		return true, "Key verified.", data.key_type
	end
	return false, type(data.error) == "string" and data.error or "Key redemption was denied.", nil
end

-- Kept for the inactive legacy layout below; it uses the same secure broker.
local function checkPremiumKey(key: string): (boolean, string, string?)
	return redeemKey(key)
end

-- Game modules are deployed by the experience owner in ServerStorage and run
-- through the server bridge. Mutable raw GitHub code is never fetched or run.
local function loadGameScript(gameName: string, tier: string): (boolean, string)
	local launcher = ReplicatedStorage:FindFirstChild("AnimulaGameLaunch")
	if not launcher or not launcher:IsA("RemoteFunction") then
		return false, "Secure game modules are not enabled for this experience."
	end
	local invoked, data = pcall(function()
		return launcher:InvokeServer(gameName, tier)
	end)
	if not invoked or type(data) ~= "table" then
		return false, "Secure game launch is unavailable."
	end
	if data.ok == true then
		return true, type(data.message) == "string" and data.message or "loaded"
	end
	return false, type(data.error) == "string" and data.error or "Game module is unavailable."
end

local GAMES_FREE = {
	"AdoptMe", "AllStarTowerDefense", "AnimeAdventures", "AnimeDimensions", "AnimeVanguards",
	"Arsenal", "BasketballZero", "BedWars", "BeeSwarmSimulator", "BladeBall", "BloxFruits",
	"BlueLockRivals", "BreakIn", "Brookhaven", "BubbleGumSimulatorInfinity", "BuildABoat",
	"DOORS", "Fisch", "Forsaken", "GrowAGarden", "Jailbreak", "KingLegacy", "MicUp",
	"MurderMystery2", "NinjaLegends", "PetSimulator99", "PetSimulatorX", "Piggy", "Pressure",
	"Rivals", "RoyaleHigh", "ShindoLife", "SolsRNG", "StealABrainrot", "StrongestBattlegrounds",
	"ToiletTowerDefense", "TowerDefenseSimulator", "TowerOfHell", "UntitledBoxingGame", "WelcomeToBloxburg",
}
local GAMES_PREMIUM = {
	"AdoptMe", "AllStarTowerDefense", "AnimeAdventures", "AnimeDimensions", "AnimeVanguards",
	"Arsenal", "BasketballZero", "BedWars", "BeeSwarmSimulator", "BladeBall", "BloxFruits",
	"BlueLockRivals", "BreakIn", "Brookhaven", "BubbleGumSimulatorInfinity", "BuildABoat",
	"DOORS", "Fisch", "Forsaken", "GrowAGarden", "Jailbreak", "KingLegacy", "MicUp",
	"MurderMystery2", "NinjaLegends", "PetSimulator99", "PetSimulatorX", "Piggy", "Pressure",
	"Rivals", "RoyaleHigh", "ShindoLife", "SolsRNG", "StealABrainrot", "StrongestBattlegrounds",
	"ToiletTowerDefense", "TowerDefenseSimulator", "TowerOfHell", "UntitledBoxingGame", "WelcomeToBloxburg",
}
local GAMES_FREEMIUM = GAMES_PREMIUM

-- Legacy loader layout retained only for source history. The runtime UI below is standalone.
if false then
-- bersihkan loader lama kalau ada (anti duplikat)
do
	local hui0 = getHui()
	for _, ch in ipairs(hui0:GetChildren()) do
		if ch:IsA("ScreenGui") and ch.Name == "AnimulaLoader" then
			pcall(function() ch:Destroy() end)
		end
	end
end

-- UI root
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
main.Size = UDim2.fromOffset(600, 430)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = T.surface
main.BorderSizePixel = 0
main.Parent = sg
corner(main, UDim.new(0, 18))
stroke(main, T.border, 1.5, 0.1)
main.ClipsDescendants = true

-- wave samar (hydro vibe)
do
	local wave = Instance.new("Frame")
	wave.Name = "WaveFX"
	wave.BackgroundColor3 = T.primary
	wave.BackgroundTransparency = 0.93
	wave.Size = UDim2.fromScale(1, 1)
	wave.BorderSizePixel = 0
	wave.ZIndex = 1
	wave.Parent = main
	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0, 18)
	wc.Parent = wave
	local wg = Instance.new("UIGradient")
	wg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.primary),
		ColorSequenceKeypoint.new(0.5, T.secondary),
		ColorSequenceKeypoint.new(1, T.primaryDark),
	})
	wg.Rotation = 18
	wg.Offset = Vector2.new(-0.2, 0)
	wg.Parent = wave
	task.spawn(function()
		local dir = 1
		while wg.Parent do
			local target = if dir == 1 then Vector2.new(0.2, 0) else Vector2.new(-0.2, 0)
			local tw = TweenService:Create(wg, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = target })
			tw:Play()
			tw.Completed:Wait()
			if not wg.Parent then break end
			dir *= -1
		end
	end)
end

-- Konten sengaja dibiarkan bersih agar fokus tetap pada navigasi dan informasi.

-- shadow 2 lapis
do
	local s = Instance.new("Frame")
	s.BackgroundColor3 = Color3.new(0, 0, 0)
	s.BackgroundTransparency = 0.82
	s.Size = UDim2.new(1, 18, 1, 18)
	s.Position = UDim2.fromOffset(-9, -9)
	s.BorderSizePixel = 0
	s.ZIndex = 0
	s.Parent = main
	corner(s, UDim.new(0, 22))
	local s2 = Instance.new("Frame")
	s2.BackgroundColor3 = T.primary
	s2.BackgroundTransparency = 0.93
	s2.Size = UDim2.new(1, 30, 1, 30)
	s2.Position = UDim2.fromOffset(-15, -15)
	s2.BorderSizePixel = 0
	s2.ZIndex = -1
	s2.Parent = main
	corner(s2, UDim.new(0, 26))
	main.ZIndex = 2
end

-- accent sederhana untuk memisahkan header tanpa mengganggu konten
do
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = T.primary
	bar.Size = UDim2.new(1, 0, 0, 2)
	bar.BorderSizePixel = 0
	bar.ZIndex = 8
	bar.Parent = main
	corner(bar, UDim.new(0, 99))
	gradient(bar, T.primary, T.secondary, 0)
end

-- glass highlight atas
do
	local hl = Instance.new("Frame")
	hl.BackgroundColor3 = Color3.new(1, 1, 1)
	hl.BackgroundTransparency = 0.94
	hl.Size = UDim2.new(1, -2, 0, 1)
	hl.Position = UDim2.fromOffset(1, 1)
	hl.BorderSizePixel = 0
	hl.ZIndex = 8
	hl.Parent = main
end

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundTransparency = 1
titleBar.Size = UDim2.new(1, 0, 0, 62)
titleBar.Position = UDim2.fromOffset(0, 4)
titleBar.ZIndex = 9
titleBar.Parent = main

-- icon + glow pulse
local iconWrap = Instance.new("Frame")
iconWrap.BackgroundColor3 = T.primary
iconWrap.Size = UDim2.fromOffset(42, 42)
iconWrap.Position = UDim2.fromOffset(16, 10)
iconWrap.ZIndex = 10
iconWrap.BorderSizePixel = 0
iconWrap.Parent = titleBar
corner(iconWrap, UDim.new(1, 0))
gradient(iconWrap, T.primary, T.secondary, 35)
stroke(iconWrap, T.gold, 1.5, 0.3)

do
	local glow = Instance.new("ImageLabel")
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857084"
	glow.ImageColor3 = T.primary
	glow.ImageTransparency = 0.55
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(24, 24, 276, 276)
	glow.Size = UDim2.new(1, 18, 1, 18)
	glow.Position = UDim2.fromOffset(-9, -9)
	glow.ZIndex = 9
	glow.Parent = iconWrap
	task.spawn(function()
		while glow.Parent do
			tween(glow, { ImageTransparency = 0.75 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Wait()
			if not glow.Parent then break end
			tween(glow, { ImageTransparency = 0.45 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Wait()
		end
	end)
end

local iconLbl = Instance.new("TextLabel")
iconLbl.BackgroundTransparency = 1
iconLbl.Size = UDim2.fromScale(1, 1)
iconLbl.Font = Enum.Font.GothamBold
iconLbl.TextSize = 21
iconLbl.TextColor3 = Color3.new(1, 1, 1)
iconLbl.Text = "◈"
iconLbl.ZIndex = 11
iconLbl.Parent = iconWrap

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.fromOffset(68, 9)
titleLbl.Size = UDim2.new(1, -180, 0, 23)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 22
titleLbl.TextColor3 = T.text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
titleLbl.Text = "Animula Hub"
titleLbl.ZIndex = 10
titleLbl.Parent = titleBar

local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency = 1
subLbl.Position = UDim2.fromOffset(68, 34)
subLbl.Size = UDim2.new(1, -180, 0, 16)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 13
subLbl.TextColor3 = T.dim
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Text = "v3  •  Premium / Free / Info"
subLbl.ZIndex = 10
subLbl.Parent = titleBar

-- status pill kanan (ONLINE)
local pill = Instance.new("Frame")
pill.BackgroundColor3 = Color3.fromRGB(16, 42, 30)
pill.Size = UDim2.fromOffset(84, 26)
pill.Position = UDim2.new(1, -126, 0, 17)
pill.ZIndex = 10
pill.BorderSizePixel = 0
pill.Parent = titleBar
corner(pill, UDim.new(1, 0))
stroke(pill, T.success, 1, 0.55)
local dot = Instance.new("Frame")
dot.BackgroundColor3 = T.success
dot.Size = UDim2.fromOffset(7, 7)
dot.Position = UDim2.fromOffset(9, 8)
dot.BorderSizePixel = 0
dot.Parent = pill
corner(dot, UDim.new(1, 0))
local pillTxt = Instance.new("TextLabel")
pillTxt.BackgroundTransparency = 1
pillTxt.Position = UDim2.fromOffset(20, 0)
pillTxt.Size = UDim2.new(1, -24, 1, 0)
pillTxt.Font = Enum.Font.GothamBold
pillTxt.TextSize = 11
pillTxt.TextColor3 = T.success
pillTxt.TextXAlignment = Enum.TextXAlignment.Left
pillTxt.Text = "ONLINE"
pillTxt.Parent = pill
task.spawn(function()
	while dot.Parent do
		tween(dot, { BackgroundTransparency = 0.4 }, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Wait()
		if not dot.Parent then break end
		tween(dot, { BackgroundTransparency = 0 }, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Wait()
	end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.BackgroundColor3 = T.surface2
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 15)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = T.dim
closeBtn.Text = "×"
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 10
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
corner(closeBtn, UDim.new(0, 8))
local closeStroke = stroke(closeBtn, T.border, 1, 0.5)
closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, { BackgroundColor3 = T.error, TextColor3 = Color3.new(1, 1, 1) }, 0.12)
	tween(closeStroke, { Color = T.error }, 0.12)
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, { BackgroundColor3 = T.surface2, TextColor3 = T.dim }, 0.12)
	tween(closeStroke, { Color = T.border }, 0.12)
end)
closeBtn.MouseButton1Click:Connect(function()
	tween(main, { BackgroundTransparency = 1 }, 0.16)
	task.wait(0.16)
	sg:Destroy()
end)

local headerDivider = Instance.new("Frame")
headerDivider.BackgroundColor3 = T.border
headerDivider.BackgroundTransparency = 0.48
headerDivider.Size = UDim2.new(1, -28, 0, 1)
headerDivider.Position = UDim2.fromOffset(14, 62)
headerDivider.BorderSizePixel = 0
headerDivider.ZIndex = 8
headerDivider.Parent = main

-- tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.BackgroundColor3 = T.surface
tabBar.BackgroundTransparency = 0.04
tabBar.Size = UDim2.new(0, 145, 1, -86)
tabBar.Position = UDim2.fromOffset(10, 68)
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 9
tabBar.Parent = main
corner(tabBar, UDim.new(0, 12))
stroke(tabBar, T.border, 1, 0.4)
pad(tabBar, 7, 8, 7, 8)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Vertical
tabLayout.Padding = UDim.new(0, 5)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local navCaption = Instance.new("TextLabel")
navCaption.Name = "NavigationCaption"
navCaption.BackgroundTransparency = 1
navCaption.Size = UDim2.new(1, 0, 0, 18)
navCaption.Font = Enum.Font.GothamBold
navCaption.TextSize = 10
navCaption.TextColor3 = T.muted
navCaption.TextXAlignment = Enum.TextXAlignment.Left
navCaption.Text = "NAVIGATION"
navCaption.LayoutOrder = 0
navCaption.Parent = tabBar

local pages: { [string]: Frame } = {}
local tabBtns: { [string]: TextButton } = {}
local currentTab = "Premium"

local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, -170, 1, -82)
body.Position = UDim2.fromOffset(160, 68)
body.ZIndex = 5
body.Parent = main

local function notify(title: string, desc: string, ok: boolean?)
	local n = Instance.new("Frame")
	n.BackgroundColor3 = if ok == false then Color3.fromRGB(60, 30, 35) else T.surface2
	n.Size = UDim2.new(1, -12, 0, 46)
	n.Position = UDim2.new(0, 6, 1, -52)
	n.BorderSizePixel = 0
	n.ZIndex = 30
	n.Parent = body
	corner(n, UDim.new(0, 10))
	stroke(n, if ok == false then T.error else T.success, 1, 0.35)
	pad(n, 10, 8, 10, 8)
	local a = Instance.new("TextLabel")
	a.BackgroundTransparency = 1
	a.Size = UDim2.new(1, 0, 0, 16)
	a.Font = Enum.Font.GothamBold
	a.TextSize = 14
	a.TextColor3 = if ok == false then T.error else T.text
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Text = title
	a.Parent = n
	local b = Instance.new("TextLabel")
	b.BackgroundTransparency = 1
	b.Position = UDim2.fromOffset(0, 17)
	b.Size = UDim2.new(1, 0, 0, 14)
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.TextColor3 = T.dim
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextWrapped = true
	b.Text = desc
	b.Parent = n
	n.BackgroundTransparency = 1
	tween(n, { BackgroundTransparency = 0 }, 0.18)
	task.delay(2.6, function()
		if n.Parent then
			tween(n, { BackgroundTransparency = 1 }, 0.2)
			task.wait(0.2)
			n:Destroy()
		end
	end)
end

local function makePage(name: string): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.Visible = false
	f.Parent = body
	local sc = Instance.new("ScrollingFrame")
	sc.Name = "Scroll"
	sc.BackgroundTransparency = 1
	sc.Size = UDim2.fromScale(1, 1)
	sc.CanvasSize = UDim2.fromOffset(0, 0)
	sc.ScrollBarThickness = 2
	sc.ScrollBarImageColor3 = T.primary
	sc.BorderSizePixel = 0
	sc.Parent = f
	pad(sc, 4, 6, 4, 6)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = sc
	local pending = false
	local function refresh()
		if pending then return end
		pending = true
		task.defer(function()
			pending = false
			if not sc.Parent then return end
			local sz = list.AbsoluteContentSize
			sc.CanvasSize = UDim2.fromOffset(0, math.clamp(sz.Y + 16, 0, 6000))
		end)
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
	task.defer(refresh)
	pages[name] = f
	return f
end

local function getScroll(page: Frame): ScrollingFrame
	return page:FindFirstChild("Scroll") :: ScrollingFrame
end

local function switchTab(name: string)
	if name == currentTab and pages[name] and pages[name].Visible then return end
	local oldPage = pages[currentTab]
	if oldPage and oldPage.Visible then
		local oldSc = oldPage:FindFirstChild("Scroll") :: ScrollingFrame?
		if oldSc then
			tween(oldSc, { Position = UDim2.new(0, -18, 0, 0) }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.delay(0.12, function()
			oldPage.Visible = false
			if oldSc then oldSc.Position = UDim2.fromOffset(0, 0) end
		end)
	end
	local newPage = pages[name]
	if newPage then
		local newSc = newPage:FindFirstChild("Scroll") :: ScrollingFrame?
		if newSc then newSc.Position = UDim2.new(0, 18, 0, 0) end
		newPage.Visible = true
		if newSc then
			newSc.CanvasPosition = Vector2.new(0, 0)
			tween(newSc, { Position = UDim2.fromOffset(0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end
	currentTab = name
	for k, b in pairs(tabBtns) do
		local isActive = k == name
		tween(b, {
			BackgroundColor3 = if isActive then T.surfaceHover else T.surface2,
			BackgroundTransparency = if isActive then 0 else 0.28,
			TextColor3 = if isActive then T.text else T.dim,
		}, 0.18)
		local st = b:FindFirstChildOfClass("UIStroke") :: UIStroke?
		if st then tween(st, {
			Color = if isActive then T.primary else T.border,
			Transparency = if isActive then 0.12 else 0.72,
		}, 0.18) end
		local indicator = b:FindFirstChild("ActiveIndicator") :: Frame?
		if indicator then tween(indicator, { BackgroundTransparency = if isActive then 0 else 1 }, 0.18) end
	end
end

-- tab buttons (premium default aktif)
for index, info in ipairs({
	{ key = "Premium", label = "◆ Premium" },
	{ key = "Free", label = "◇ Free" },
	{ key = "Info", label = "ⓘ Info" },
}) do
	local b = Instance.new("TextButton")
	b.Name = info.key
	b.BackgroundColor3 = if info.key == currentTab then T.surfaceHover else T.surface2
	b.BackgroundTransparency = if info.key == currentTab then 0 else 0.28
	b.Size = UDim2.new(1, 0, 0, 38)
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.TextColor3 = if info.key == currentTab then T.text else T.dim
	b.Text = string.gsub(info.label, "^%S+%s*", "")
	b.LayoutOrder = index
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.ZIndex = 9
	b.Parent = tabBar
	corner(b, UDim.new(0, 9))
	local st = stroke(b, if info.key == currentTab then T.primary else T.border, 1, if info.key == currentTab then 0.12 else 0.72)
	pad(b, 11, 0, 8, 0)
	local indicator = Instance.new("Frame")
	indicator.Name = "ActiveIndicator"
	indicator.BackgroundColor3 = T.secondary
	indicator.BackgroundTransparency = if info.key == currentTab then 0 else 1
	indicator.Size = UDim2.fromOffset(3, 20)
	indicator.Position = UDim2.new(0, 0, 0.5, -10)
	indicator.BorderSizePixel = 0
	indicator.Parent = b
	corner(indicator, UDim.new(1, 0))
	tabBtns[info.key] = b
	ripple(b, Color3.new(1, 1, 1))
	b.MouseEnter:Connect(function()
		if currentTab ~= info.key then tween(b, { BackgroundColor3 = T.surfaceHover }, 0.12) end
	end)
	b.MouseLeave:Connect(function()
		if currentTab ~= info.key then tween(b, { BackgroundColor3 = T.surface2 }, 0.12) end
	end)
	b.MouseButton1Down:Connect(function()
		tween(b, { Size = UDim2.new(1, -2, 0, 36) }, 0.07)
	end)
	b.MouseButton1Up:Connect(function()
		tween(b, { Size = UDim2.new(1, 0, 0, 38) }, 0.1, Enum.EasingStyle.Back)
	end)
	b.MouseButton1Click:Connect(function() switchTab(info.key) end)
end

local function sectionTitle(parent: Instance, text: string)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 18)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 15
	l.TextColor3 = T.accent
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = parent
	return l
end

local function gameGrid(parent: Instance, games: { string }, selected: { value: string? }, buttons: { [string]: TextButton }, onPick: (string) -> ())
	sectionTitle(parent, "Pilih Game")
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Parent = parent
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(132, 36)
	layout.CellPadding = UDim2.fromOffset(6, 6)
	layout.FillDirectionMaxCells = 3
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = grid
	for _, gname in ipairs(games) do
		local b = Instance.new("TextButton")
		b.Name = gname
		b.BackgroundColor3 = T.surface
		b.Font = Enum.Font.Gotham
		b.TextSize = 13
		b.TextColor3 = T.dim
		b.TextTruncate = Enum.TextTruncate.AtEnd
		b.Text = gname
		b.AutoButtonColor = false
		b.BorderSizePixel = 0
		b.ZIndex = 6
		b.Parent = grid
		corner(b, UDim.new(0, 8))
		local st = stroke(b, T.border, 1, 0.35)
		ripple(b, T.primary)
		b.MouseEnter:Connect(function()
			if selected.value ~= gname then
				tween(b, { BackgroundColor3 = T.surfaceHover }, 0.12)
				tween(st, { Color = T.secondary }, 0.12)
			end
		end)
		b.MouseLeave:Connect(function()
			if selected.value ~= gname then
				tween(b, { BackgroundColor3 = T.surface }, 0.12)
				tween(st, { Color = T.border }, 0.12)
			end
		end)
		b.MouseButton1Click:Connect(function()
			selected.value = gname
			onPick(gname)
			for n, btn in pairs(buttons) do
				local isSel = n == gname
				tween(btn, {
					BackgroundColor3 = if isSel then T.primary else T.surface,
					TextColor3 = if isSel then Color3.new(1, 1, 1) else T.dim,
				}, 0.15)
				local bst = btn:FindFirstChildOfClass("UIStroke") :: UIStroke?
				if bst then tween(bst, { Color = if isSel then T.accent else T.border }, 0.15) end
			end
		end)
		buttons[gname] = b
	end
	return grid
end

local function primaryButton(parent: Instance, text: string): TextButton
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = T.primary
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.ZIndex = 6
	btn.Parent = parent
	corner(btn, UDim.new(0, 9))
	stroke(btn, T.borderLight, 1, 0.55)
	ripple(btn, Color3.new(1, 1, 1))
	btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Color3.fromRGB(96, 176, 255) }, 0.12) end)
	btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = T.primary }, 0.12) end)
	btn.MouseButton1Down:Connect(function() tween(btn, { Size = UDim2.new(1, -2, 0, 38) }, 0.07) end)
	btn.MouseButton1Up:Connect(function() tween(btn, { Size = UDim2.new(1, 0, 0, 40) }, 0.1, Enum.EasingStyle.Back) end)
	return btn
end

local function guideCard(parent: Instance, title: string, description: string): Frame
	local card = Instance.new("Frame")
	card.BackgroundColor3 = T.surface
	card.Size = UDim2.new(1, 0, 0, 96)
	card.BorderSizePixel = 0
	card.ZIndex = 6
	card.Parent = parent
	corner(card, UDim.new(0, 11))
	stroke(card, T.border, 1, 0.48)
	pad(card, 13, 11, 13, 11)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 18)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = T.text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.Parent = card

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = T.border
	divider.BackgroundTransparency = 0.35
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 25)
	divider.BorderSizePixel = 0
	divider.Parent = card

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(0, 34)
	body.Size = UDim2.new(1, 0, 0, 46)
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextColor3 = T.dim
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Text = description
	body.Parent = card
	return card
end

-- TAB: PREMIUM
local premiumPage = makePage("Premium")
local premiumState = {
	unlocked = false,
	selected = { value = nil :: string? },
	buttons = {} :: { [string]: TextButton },
	keyBox = nil :: TextBox?,
	status = nil :: TextLabel?,
	checkBtn = nil :: TextButton?,
	gameWrap = nil :: Frame?,
}
do
	local sc = getScroll(premiumPage)
	sectionTitle(sc, "Akses Premium")

	local card = Instance.new("Frame")
	card.BackgroundColor3 = T.surface2
	card.Size = UDim2.new(1, 0, 0, 148)
	card.BorderSizePixel = 0
	card.ZIndex = 6
	card.Parent = sc
	corner(card, UDim.new(0, 12))
	stroke(card, T.border, 1, 0.52)
	pad(card, 16, 14, 16, 14)

	local l1 = Instance.new("TextLabel")
	l1.BackgroundTransparency = 1
	l1.Size = UDim2.new(1, 0, 0, 20)
	l1.Font = Enum.Font.GothamBold
	l1.TextSize = 16
	l1.TextColor3 = T.text
	l1.TextXAlignment = Enum.TextXAlignment.Left
	l1.Text = "Key Premium"
	l1.Parent = card

	local l2 = Instance.new("TextLabel")
	l2.BackgroundTransparency = 1
	l2.Position = UDim2.fromOffset(0, 25)
	l2.Size = UDim2.new(1, 0, 0, 16)
	l2.Font = Enum.Font.Gotham
	l2.TextSize = 13
	l2.TextColor3 = T.muted
	l2.TextXAlignment = Enum.TextXAlignment.Left
	l2.Text = "Key akan dihubungkan ke akun Roblox ini."
	l2.Parent = card

	local keyBox = Instance.new("TextBox")
	keyBox.BackgroundColor3 = T.bg
	keyBox.Size = UDim2.new(1, -116, 0, 40)
	keyBox.Position = UDim2.fromOffset(0, 57)
	keyBox.Font = Enum.Font.Gotham
	keyBox.TextSize = 14
	keyBox.TextColor3 = T.text
	keyBox.PlaceholderText = "Tempel key Premium di sini"
	keyBox.PlaceholderColor3 = T.muted
	keyBox.Text = ""
	keyBox.ClearTextOnFocus = false
	keyBox.BorderSizePixel = 0
	keyBox.ZIndex = 7
	keyBox.Parent = card
	corner(keyBox, UDim.new(0, 8))
	local keyStroke = stroke(keyBox, T.border, 1, 0.4)
	pad(keyBox, 9, 0, 9, 0)
	keyBox.Focused:Connect(function() tween(keyStroke, { Color = T.primary }, 0.15) end)
	keyBox.FocusLost:Connect(function() tween(keyStroke, { Color = T.border }, 0.15) end)
	premiumState.keyBox = keyBox

	local checkBtn = Instance.new("TextButton")
	checkBtn.BackgroundColor3 = T.primary
	checkBtn.Size = UDim2.fromOffset(106, 40)
	checkBtn.Position = UDim2.new(1, -106, 0, 57)
	checkBtn.Font = Enum.Font.GothamBold
	checkBtn.TextSize = 14
	checkBtn.TextColor3 = Color3.new(1, 1, 1)
	checkBtn.Text = "Verifikasi"
	checkBtn.AutoButtonColor = false
	checkBtn.BorderSizePixel = 0
	checkBtn.ZIndex = 7
	checkBtn.Parent = card
	corner(checkBtn, UDim.new(0, 8))
	ripple(checkBtn, Color3.new(1, 1, 1))
	checkBtn.MouseEnter:Connect(function() tween(checkBtn, { BackgroundColor3 = Color3.fromRGB(96, 176, 255) }, 0.12) end)
	checkBtn.MouseLeave:Connect(function()
		if not premiumState.unlocked then tween(checkBtn, { BackgroundColor3 = T.primary }, 0.12) end
	end)
	premiumState.checkBtn = checkBtn

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.fromOffset(0, 108)
	hint.Size = UDim2.new(1, 0, 0, 14)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 12
	hint.TextColor3 = T.muted
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = "Belum punya key? Gunakan key Free."
	hint.Parent = card

	local statusLbl = Instance.new("TextLabel")
	statusLbl.BackgroundTransparency = 1
	statusLbl.Size = UDim2.new(1, 0, 0, 15)
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 12
	statusLbl.TextColor3 = T.dim
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Text = ""
	statusLbl.Visible = false
	statusLbl.Parent = sc
	premiumState.status = statusLbl

	local premiumGuide = guideCard(sc, "Cara menggunakan", "1. Tempel key Premium Anda.\n2. Tekan Verifikasi.\n3. Pilih game setelah akses terbuka.")

	local gameWrap = Instance.new("Frame")
	gameWrap.BackgroundTransparency = 1
	gameWrap.Size = UDim2.new(1, 0, 0, 0)
	gameWrap.AutomaticSize = Enum.AutomaticSize.Y
	gameWrap.Visible = false
	gameWrap.Parent = sc
	local glist = Instance.new("UIListLayout")
	glist.FillDirection = Enum.FillDirection.Vertical
	glist.Padding = UDim.new(0, 8)
	glist.SortOrder = Enum.SortOrder.LayoutOrder
	glist.Parent = gameWrap
	premiumState.gameWrap = gameWrap

	gameGrid(gameWrap, GAMES_PREMIUM, premiumState.selected, premiumState.buttons, function() end)

	local loadBtn = primaryButton(gameWrap, "Jalankan Script Premium")
	loadBtn.LayoutOrder = 99

	checkBtn.MouseButton1Click:Connect(function()
		local key = keyBox.Text
		statusLbl.Visible = true
		statusLbl.Text = "⏳ ngecek..."
		statusLbl.TextColor3 = T.dim
		tween(keyStroke, { Color = T.primary }, 0.15)
		task.wait(0.08)
		local okR, msgR = redeemKey(key)
		if okR then
			premiumState.unlocked = true
			premiumGuide.Visible = false
			statusLbl.Text = "✓ " .. msgR
			statusLbl.TextColor3 = T.success
			gameWrap.Visible = true
			tween(checkBtn, { BackgroundColor3 = T.success }, 0.2)
			checkBtn.Text = "Terverifikasi"
			notify("Keys valid", "premium kebuka, pilih game lalu load", true)
		else
			local ok, msg = checkPremiumKey(key)
			if ok and string.find(msgR, "already redeemed") then
				premiumState.unlocked = true
				premiumGuide.Visible = false
				statusLbl.Text = "✓ " .. msg .. " (welcome back)"
				statusLbl.TextColor3 = T.success
				gameWrap.Visible = true
				checkBtn.Text = "Terverifikasi"
				notify("Keys valid", "welcome back", true)
			else
				premiumState.unlocked = false
				statusLbl.Text = "✗ " .. msgR
				statusLbl.TextColor3 = T.error
				gameWrap.Visible = false
				tween(keyStroke, { Color = T.error }, 0.15)
				notify("Keys salah", msgR, false)
			end
		end
	end)

	loadBtn.MouseButton1Click:Connect(function()
		if not premiumState.unlocked then notify("Keys belum valid", "check keys dulu", false) return end
		local sel = premiumState.selected.value
		if not sel then notify("Pilih game dulu", "klik salah satu game premium", false) return end
		local ok, msg = checkPremiumKey(keyBox.Text)
		if not ok then notify("Key expired", msg, false) return end
		notify("Loading Premium", sel .. " ...", true)
		task.wait(0.25)
		local loaded, err = loadGameScript(sel, "Premium")
		if loaded then
			sg:Destroy()
		else
			notify("Gagal memuat", err, false)
		end
	end)
end

-- TAB: FREE
local freePage = makePage("Free")
local freeState = {
	confirmed = false,
	selected = { value = nil :: string? },
	buttons = {} :: { [string]: TextButton },
}
do
	local sc = getScroll(freePage)
	sectionTitle(sc, "Akses Gratis")

	local card = Instance.new("Frame")
	card.BackgroundColor3 = T.surface2
	card.Size = UDim2.new(1, 0, 0, 84)
	card.BorderSizePixel = 0
	card.ZIndex = 6
	card.Parent = sc
	corner(card, UDim.new(0, 12))
	stroke(card, T.border, 1, 0.52)
	pad(card, 16, 14, 16, 14)

	local t1 = Instance.new("TextLabel")
	t1.BackgroundTransparency = 1
	t1.Size = UDim2.new(1, -96, 0, 15)
	t1.Font = Enum.Font.GothamBold
	t1.TextSize = 16
	t1.TextColor3 = T.text
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.Text = "Akses Free"
	t1.Parent = card

	local t2 = Instance.new("TextLabel")
	t2.BackgroundTransparency = 1
	t2.Position = UDim2.fromOffset(0, 25)
	t2.Size = UDim2.new(1, -116, 0, 16)
	t2.Font = Enum.Font.Gotham
	t2.TextSize = 13
	t2.TextColor3 = T.muted
	t2.TextXAlignment = Enum.TextXAlignment.Left
	t2.Text = "Konfirmasi untuk melihat game yang tersedia."
	t2.Parent = card

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.BackgroundColor3 = T.surface
	confirmBtn.Size = UDim2.fromOffset(106, 40)
	confirmBtn.Position = UDim2.new(1, -106, 0.5, -20)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 14
	confirmBtn.TextColor3 = T.dim
	confirmBtn.Text = "Buka Game"
	confirmBtn.AutoButtonColor = false
	confirmBtn.BorderSizePixel = 0
	confirmBtn.ZIndex = 7
	confirmBtn.Parent = card
	corner(confirmBtn, UDim.new(0, 8))
	local confirmStroke = stroke(confirmBtn, T.border, 1, 0.4)
	ripple(confirmBtn, Color3.new(1, 1, 1))

	local freeGuide = guideCard(sc, "Mode Free", "1. Tekan Buka Game untuk membuka daftar game.\n2. Pilih game yang ingin dimainkan.\n3. Jalankan script dari tombol di bawah.")

	local gameWrapFree = Instance.new("Frame")
	gameWrapFree.BackgroundTransparency = 1
	gameWrapFree.Size = UDim2.new(1, 0, 0, 0)
	gameWrapFree.AutomaticSize = Enum.AutomaticSize.Y
	gameWrapFree.Visible = false
	gameWrapFree.Parent = sc
	local gl = Instance.new("UIListLayout")
	gl.FillDirection = Enum.FillDirection.Vertical
	gl.Padding = UDim.new(0, 8)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = gameWrapFree

	gameGrid(gameWrapFree, GAMES_FREE, freeState.selected, freeState.buttons, function() end)

	local loadFree = primaryButton(gameWrapFree, "Jalankan Script Free")
	loadFree.LayoutOrder = 99

	confirmBtn.MouseButton1Click:Connect(function()
		freeState.confirmed = not freeState.confirmed
		local on = freeState.confirmed
		tween(confirmBtn, {
			BackgroundColor3 = if on then T.success else T.surface,
			TextColor3 = if on then Color3.new(1, 1, 1) else T.dim,
		}, 0.15)
		tween(confirmStroke, { Color = if on then T.success else T.border }, 0.15)
		confirmBtn.Text = if on then "Terbuka ✓" else "Buka Game"
		freeGuide.Visible = not on
		gameWrapFree.Visible = on
		if on then notify("Free confirmed", "pilih game lalu load", true) end
	end)

	loadFree.MouseButton1Click:Connect(function()
		if not freeState.confirmed then notify("Confirm dulu", "klik confirm di atas", false) return end
		local sel = freeState.selected.value
		if not sel then notify("Pilih game dulu", "klik salah satu game free", false) return end
		notify("Loading Free", sel .. " ...", true)
		task.wait(0.25)
		local loaded, err = loadGameScript(sel, "Free")
		if loaded then
			sg:Destroy()
		else
			notify("Gagal memuat", err, false)
		end
	end)
end

-- TAB: INFO
local infoPage = makePage("Info")
do
	local sc = getScroll(infoPage)
	sectionTitle(sc, "Tentang")

	local function infoCard(title: string, desc: string)
		local c = Instance.new("Frame")
		c.BackgroundColor3 = T.surface2
		c.Size = UDim2.new(1, 0, 0, 68)
		c.BorderSizePixel = 0
		c.ZIndex = 6
		c.Parent = sc
		corner(c, UDim.new(0, 12))
		stroke(c, T.border, 1, 0.56)
		pad(c, 12, 9, 12, 9)
		local a = Instance.new("TextLabel")
		a.BackgroundTransparency = 1
		a.Size = UDim2.new(1, 0, 0, 18)
		a.Font = Enum.Font.GothamBold
		a.TextSize = 14
		a.TextColor3 = T.text
		a.TextXAlignment = Enum.TextXAlignment.Left
		a.Text = title
		a.Parent = c
		local b = Instance.new("TextLabel")
		b.BackgroundTransparency = 1
		b.Position = UDim2.fromOffset(0, 22)
		b.Size = UDim2.new(1, 0, 0, 34)
		b.Font = Enum.Font.Gotham
		b.TextSize = 12
		b.TextColor3 = T.dim
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.TextWrapped = true
		b.Text = desc
		b.Parent = c
		return c
	end

	infoCard("Animula Hub", "Premium memakai key yang terhubung ke akun Roblox. Mode Free dapat digunakan setelah konfirmasi.")
	infoCard("Loader", "Tekan tombol di bawah untuk menyalin loader ke clipboard.")
	infoCard("Support", "Gunakan Discord bila ada masalah dengan akses Premium.")

	local loaderBtn = primaryButton(sc, "Copy Loader")
	loaderBtn.MouseButton1Click:Connect(function()
		if setclipboard then setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/Script/main/MainScript/LoaderScript.lua"))()') end
		notify("Loader copied", "tempelkan script ini di executor kamu", true)
	end)
end

-- draggable (title bar)
do
	local dragging = false
	local start = Vector2.zero
	local startPos = main.Position
	titleBar.InputBegan:Connect(function(i: InputObject)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			start = Vector2.new(i.Position.X, i.Position.Y)
			startPos = main.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i: InputObject)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = Vector2.new(i.Position.X, i.Position.Y) - start
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- toggle key
UserInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
	end
end)

-- entrance
main.Size = UDim2.fromOffset(560, 395)
main.BackgroundTransparency = 0.25
tween(main, { Size = UDim2.fromOffset(600, 430) }, 0.34, Enum.EasingStyle.Back)
tween(main, { BackgroundTransparency = 0 }, 0.22)

-- default tab (setelah pages dibuat)
switchTab("Free")
switchTab("Premium")
print("[Animula Loader] v3 ready - Premium / Free / Info")
end

-- Standalone loader UI. This is the only runtime interface in this file.
do
    local function clearPreviousLoader()
        local root = getHui()
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == "AnimulaLoader" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    clearPreviousLoader()

    local root = getHui()
    local loaderGui = Instance.new("ScreenGui")
    loaderGui.Name = "AnimulaLoader"
    loaderGui.ResetOnSpawn = false
    loaderGui.IgnoreGuiInset = true
    loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loaderGui.DisplayOrder = 20
    loaderGui.Parent = root

    local glowLayer = Instance.new("Frame")
    glowLayer.Name = "CornerGlowLayer"
    glowLayer.BackgroundTransparency = 1
    glowLayer.AnchorPoint = Vector2.new(0.5, 0.5)
    glowLayer.Position = UDim2.fromScale(0.5, 0.5)
    glowLayer.Size = UDim2.fromOffset(630, 440)
    glowLayer.ZIndex = 1
    glowLayer.Parent = loaderGui

    local function makeCornerGlow(position: UDim2)
        local glow = Instance.new("ImageLabel")
        glow.Name = "CornerGlow"
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = T.primary
        glow.ImageTransparency = 0.16
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(24, 24, 276, 276)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = position
        glow.Size = UDim2.fromOffset(96, 96)
        glow.ZIndex = 1
        glow.Parent = glowLayer
    end

    makeCornerGlow(UDim2.fromOffset(0, 0))
    makeCornerGlow(UDim2.new(1, 0, 0, 0))
    makeCornerGlow(UDim2.new(0, 0, 1, 0))
    makeCornerGlow(UDim2.fromScale(1, 1))

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.BackgroundColor3 = T.surface
    main.BorderSizePixel = 0
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(630, 440)
    main.ClipsDescendants = true
    main.ZIndex = 5
    main.Parent = loaderGui
    corner(main, UDim.new(0, 16))
    stroke(main, T.primary, 1.8, 0.12)

    local function edge(position: UDim2, size: UDim2)
        local line = Instance.new("Frame")
        line.BackgroundColor3 = T.secondary
        line.BackgroundTransparency = 0.22
        line.Position = position
        line.Size = size
        line.BorderSizePixel = 0
        line.ZIndex = 7
        line.Parent = main
        corner(line, UDim.new(1, 0))
    end

    edge(UDim2.fromOffset(18, 2), UDim2.new(1, -36, 0, 1))
    edge(UDim2.new(0, 18, 1, -3), UDim2.new(1, -36, 0, 1))
    edge(UDim2.fromOffset(2, 18), UDim2.new(0, 1, 1, -36))
    edge(UDim2.new(1, -3, 0, 18), UDim2.new(0, 1, 1, -36))

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 68)
    header.ZIndex = 8
    header.Parent = main

    local logo = Instance.new("Frame")
    logo.BackgroundColor3 = T.primary
    logo.BorderSizePixel = 0
    logo.Position = UDim2.fromOffset(18, 14)
    logo.Size = UDim2.fromOffset(40, 40)
    logo.ZIndex = 9
    logo.Parent = header
    corner(logo, UDim.new(0, 12))
    stroke(logo, T.accent, 1, 0.18)

    local logoText = Instance.new("TextLabel")
    logoText.BackgroundTransparency = 1
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 18
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.Text = "A"
    logoText.ZIndex = 10
    logoText.Parent = logo

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(72, 21)
    title.Size = UDim2.new(1, -132, 0, 26)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = T.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Text = "Animula Hub"
    title.ZIndex = 9
    title.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.BackgroundColor3 = T.surface2
    closeButton.BorderSizePixel = 0
    closeButton.Position = UDim2.new(1, -46, 0, 20)
    closeButton.Size = UDim2.fromOffset(28, 28)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.TextColor3 = T.dim
    closeButton.Text = "X"
    closeButton.AutoButtonColor = false
    closeButton.ZIndex = 9
    closeButton.Parent = header
    corner(closeButton, UDim.new(0, 8))
    local closeStroke = stroke(closeButton, T.border, 1, 0.55)
    closeButton.MouseEnter:Connect(function()
        tween(closeButton, { BackgroundColor3 = T.error, TextColor3 = Color3.new(1, 1, 1) }, 0.12)
        tween(closeStroke, { Color = T.error }, 0.12)
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, { BackgroundColor3 = T.surface2, TextColor3 = T.dim }, 0.12)
        tween(closeStroke, { Color = T.border }, 0.12)
    end)
    closeButton.MouseButton1Click:Connect(function()
        loaderGui:Destroy()
    end)

    local divider = Instance.new("Frame")
    divider.BackgroundColor3 = T.border
    divider.BackgroundTransparency = 0.42
    divider.Position = UDim2.fromOffset(14, 68)
    divider.Size = UDim2.new(1, -28, 0, 1)
    divider.BorderSizePixel = 0
    divider.ZIndex = 8
    divider.Parent = main

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = T.bg
    sidebar.BackgroundTransparency = 0.12
    sidebar.Position = UDim2.fromOffset(14, 82)
    sidebar.Size = UDim2.new(0, 152, 1, -96)
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 8
    sidebar.Parent = main
    corner(sidebar, UDim.new(0, 12))
    stroke(sidebar, T.border, 1, 0.5)

    local navLabel = Instance.new("TextLabel")
    navLabel.BackgroundTransparency = 1
    navLabel.Position = UDim2.fromOffset(13, 13)
    navLabel.Size = UDim2.new(1, -26, 0, 16)
    navLabel.Font = Enum.Font.GothamBold
    navLabel.TextSize = 11
    navLabel.TextColor3 = T.muted
    navLabel.TextXAlignment = Enum.TextXAlignment.Left
    navLabel.Text = "NAVIGATION"
    navLabel.ZIndex = 9
    navLabel.Parent = sidebar

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(182, 82)
    content.Size = UDim2.new(1, -198, 1, -96)
    content.ZIndex = 8
    content.Parent = main

    local pages: { [string]: Frame } = {}
    local tabButtons: { [string]: { button: TextButton, indicator: Frame, stroke: UIStroke } } = {}
    local activeTab = "Premium"

    local function toast(titleText: string, message: string, success: boolean)
        local toastFrame = Instance.new("Frame")
        toastFrame.BackgroundColor3 = if success then Color3.fromRGB(18, 61, 47) else Color3.fromRGB(68, 35, 44)
        toastFrame.BackgroundTransparency = 0.05
        toastFrame.AnchorPoint = Vector2.new(0.5, 1)
        toastFrame.Position = UDim2.new(0.5, 0, 1, -10)
        toastFrame.Size = UDim2.new(1, -8, 0, 52)
        toastFrame.BorderSizePixel = 0
        toastFrame.ZIndex = 30
        toastFrame.Parent = content
        corner(toastFrame, UDim.new(0, 10))
        stroke(toastFrame, if success then T.success else T.error, 1, 0.28)

        local toastTitle = Instance.new("TextLabel")
        toastTitle.BackgroundTransparency = 1
        toastTitle.Position = UDim2.fromOffset(12, 7)
        toastTitle.Size = UDim2.new(1, -24, 0, 16)
        toastTitle.Font = Enum.Font.GothamBold
        toastTitle.TextSize = 13
        toastTitle.TextColor3 = T.text
        toastTitle.TextXAlignment = Enum.TextXAlignment.Left
        toastTitle.Text = titleText
        toastTitle.ZIndex = 31
        toastTitle.Parent = toastFrame

        local toastMessage = Instance.new("TextLabel")
        toastMessage.BackgroundTransparency = 1
        toastMessage.Position = UDim2.fromOffset(12, 25)
        toastMessage.Size = UDim2.new(1, -24, 0, 16)
        toastMessage.Font = Enum.Font.Gotham
        toastMessage.TextSize = 12
        toastMessage.TextColor3 = T.dim
        toastMessage.TextXAlignment = Enum.TextXAlignment.Left
        toastMessage.Text = message
        toastMessage.ZIndex = 31
        toastMessage.Parent = toastFrame

        task.delay(3, function()
            if toastFrame.Parent then toastFrame:Destroy() end
        end)
    end

    local function makePage(name: string): ScrollingFrame
        local page = Instance.new("Frame")
        page.Name = name
        page.BackgroundTransparency = 1
        page.Size = UDim2.fromScale(1, 1)
        page.Visible = false
        page.ZIndex = 8
        page.Parent = content

        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Scroll"
        scroll.BackgroundTransparency = 1
        scroll.Size = UDim2.fromScale(1, 1)
        scroll.CanvasSize = UDim2.fromOffset(0, 0)
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = T.primary
        scroll.BorderSizePixel = 0
        scroll.ZIndex = 8
        scroll.Parent = page
        pad(scroll, 2, 2, 2, 12)

        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Vertical
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 10)
        list.Parent = scroll
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 14)
        end)

        pages[name] = page
        return scroll
    end

    local function addPageTitle(parent: Instance, heading: string, description: string)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, 0, 0, 48)
        holder.ZIndex = 8
        holder.Parent = parent

        local headingLabel = Instance.new("TextLabel")
        headingLabel.BackgroundTransparency = 1
        headingLabel.Size = UDim2.new(1, 0, 0, 23)
        headingLabel.Font = Enum.Font.GothamBold
        headingLabel.TextSize = 19
        headingLabel.TextColor3 = T.text
        headingLabel.TextXAlignment = Enum.TextXAlignment.Left
        headingLabel.Text = heading
        headingLabel.ZIndex = 9
        headingLabel.Parent = holder

        local descLabel = Instance.new("TextLabel")
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.fromOffset(0, 26)
        descLabel.Size = UDim2.new(1, 0, 0, 17)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 13
        descLabel.TextColor3 = T.muted
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Text = description
        descLabel.ZIndex = 9
        descLabel.Parent = holder
    end

    local function makeCard(parent: Instance, height: number): Frame
        local card = Instance.new("Frame")
        card.BackgroundColor3 = T.surface2
        card.Size = UDim2.new(1, 0, 0, height)
        card.BorderSizePixel = 0
        card.ZIndex = 8
        card.Parent = parent
        corner(card, UDim.new(0, 12))
        stroke(card, T.border, 1, 0.52)
        return card
    end

    local function label(parent: Instance, text: string, position: UDim2, size: UDim2, textSize: number, color: Color3, bold: boolean): TextLabel
        local item = Instance.new("TextLabel")
        item.BackgroundTransparency = 1
        item.Position = position
        item.Size = size
        item.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
        item.TextSize = textSize
        item.TextColor3 = color
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextYAlignment = Enum.TextYAlignment.Top
        item.TextWrapped = true
        item.Text = text
        item.ZIndex = 9
        item.Parent = parent
        return item
    end

    local function showTab(name: string)
        activeTab = name
        for tabName, page in pairs(pages) do
            page.Visible = tabName == name
        end
        for tabName, state in pairs(tabButtons) do
            local selected = tabName == name
            tween(state.button, {
                BackgroundColor3 = if selected then T.surfaceHover else T.surface2,
                BackgroundTransparency = if selected then 0 else 0.35,
                TextColor3 = if selected then T.text else T.dim,
            }, 0.15)
            tween(state.stroke, {
                Color = if selected then T.primary else T.border,
                Transparency = if selected then 0.08 else 0.78,
            }, 0.15)
            tween(state.indicator, { BackgroundTransparency = if selected then 0 else 1 }, 0.15)
        end
    end

    local function makeTab(name: string, order: number)
        local button = Instance.new("TextButton")
        button.Name = name
        button.BackgroundColor3 = T.surface2
        button.BackgroundTransparency = 0.35
        button.Position = UDim2.fromOffset(7, 40 + (order - 1) * 48)
        button.Size = UDim2.new(1, -14, 0, 42)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 14
        button.TextColor3 = T.dim
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = name
        button.ZIndex = 9
        button.Parent = sidebar
        corner(button, UDim.new(0, 9))
        local tabStroke = stroke(button, T.border, 1, 0.78)
        pad(button, 22, 0, 10, 0)

        local indicator = Instance.new("Frame")
        indicator.Name = "ActiveIndicator"
        indicator.BackgroundColor3 = T.secondary
        indicator.BackgroundTransparency = 1
        indicator.Position = UDim2.fromOffset(7, 10)
        indicator.Size = UDim2.fromOffset(3, 20)
        indicator.BorderSizePixel = 0
        indicator.ZIndex = 10
        indicator.Parent = button
        corner(indicator, UDim.new(1, 0))

        button.MouseEnter:Connect(function()
            if activeTab ~= name then tween(button, { BackgroundColor3 = T.surfaceHover }, 0.12) end
        end)
        button.MouseLeave:Connect(function()
            if activeTab ~= name then tween(button, { BackgroundColor3 = T.surface2 }, 0.12) end
        end)
        button.MouseButton1Click:Connect(function()
            showTab(name)
        end)
        tabButtons[name] = { button = button, indicator = indicator, stroke = tabStroke }
    end

    local function verifyAccess(key: string, expectedKeyType: string): boolean
        local redeemed, _, redeemedKeyType = redeemKey(key)
        return redeemed and redeemedKeyType == expectedKeyType
    end

    local function makeGameList(parent: Instance, games: { string }, tier: string): Frame
        local wrap = Instance.new("Frame")
        wrap.Name = "GameList"
        wrap.BackgroundTransparency = 1
        wrap.Size = UDim2.new(1, 0, 0, 0)
        wrap.AutomaticSize = Enum.AutomaticSize.Y
        wrap.Visible = false
        wrap.ZIndex = 8
        wrap.Parent = parent

        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Vertical
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 10)
        list.Parent = wrap

        local listTitle = label(wrap, "Available games", UDim2.fromOffset(2, 0), UDim2.new(1, -2, 0, 20), 15, T.accent, true)
        listTitle.LayoutOrder = 1

        local grid = Instance.new("Frame")
        grid.BackgroundTransparency = 1
        local rows = math.ceil(#games / 2)
        grid.Size = UDim2.new(1, 0, 0, rows * 38 + math.max(0, rows - 1) * 8)
        grid.LayoutOrder = 2
        grid.ZIndex = 8
        grid.Parent = wrap

        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.fromOffset(206, 38)
        gridLayout.CellPadding = UDim2.fromOffset(8, 8)
        gridLayout.FillDirectionMaxCells = 2
        gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = grid

        local selected = { value = nil :: string? }
        local buttons: { [string]: TextButton } = {}
        for _, gameName in ipairs(games) do
            local gameButton = Instance.new("TextButton")
            gameButton.Name = gameName
            gameButton.BackgroundColor3 = T.surface
            gameButton.BorderSizePixel = 0
            gameButton.Font = Enum.Font.Gotham
            gameButton.TextSize = 13
            gameButton.TextColor3 = T.dim
            gameButton.TextTruncate = Enum.TextTruncate.AtEnd
            gameButton.Text = gameName
            gameButton.AutoButtonColor = false
            gameButton.ZIndex = 9
            gameButton.Parent = grid
            corner(gameButton, UDim.new(0, 8))
            local gameStroke = stroke(gameButton, T.border, 1, 0.62)
            gameButton.MouseEnter:Connect(function()
                if selected.value ~= gameName then tween(gameButton, { BackgroundColor3 = T.surfaceHover }, 0.12) end
            end)
            gameButton.MouseLeave:Connect(function()
                if selected.value ~= gameName then tween(gameButton, { BackgroundColor3 = T.surface }, 0.12) end
            end)
            gameButton.MouseButton1Click:Connect(function()
                selected.value = gameName
                for name, item in pairs(buttons) do
                    local isSelected = name == gameName
                    tween(item, {
                        BackgroundColor3 = if isSelected then T.primary else T.surface,
                        TextColor3 = if isSelected then Color3.new(1, 1, 1) else T.dim,
                    }, 0.14)
                    local itemStroke = item:FindFirstChildOfClass("UIStroke")
                    if itemStroke then tween(itemStroke, { Color = if isSelected then T.accent else T.border }, 0.14) end
                end
            end)
            buttons[gameName] = gameButton
            gameStroke.Transparency = 0.62
        end

        local launch = Instance.new("TextButton")
        launch.BackgroundColor3 = T.primary
        launch.BorderSizePixel = 0
        launch.Size = UDim2.new(1, 0, 0, 40)
        launch.Font = Enum.Font.GothamBold
        launch.TextSize = 14
        launch.TextColor3 = Color3.new(1, 1, 1)
        launch.Text = "Launch selected game"
        launch.AutoButtonColor = false
        launch.ZIndex = 9
        launch.LayoutOrder = 3
        launch.Parent = wrap
        corner(launch, UDim.new(0, 9))
        stroke(launch, T.borderLight, 1, 0.45)
        launch.MouseEnter:Connect(function() tween(launch, { BackgroundColor3 = T.secondary }, 0.12) end)
        launch.MouseLeave:Connect(function() tween(launch, { BackgroundColor3 = T.primary }, 0.12) end)
        launch.MouseButton1Click:Connect(function()
            if not selected.value then
                toast("Select a game", "Choose a game before launching.", false)
                return
            end
            task.spawn(function()
                local loaded, message = loadGameScript(selected.value :: string, tier)
                if loaded then
                    loaderGui:Destroy()
                else
                    toast("Launch failed", "The selected game script is not available.", false)
                    warn("[Animula] " .. message)
                end
            end)
        end)
        return wrap
    end

    local function makeLockedState(parent: Instance, titleText: string, message: string): Frame
        local state = makeCard(parent, 104)
        state.Name = "LockedState"
        label(state, titleText, UDim2.fromOffset(16, 15), UDim2.new(1, -32, 0, 20), 16, T.text, true)
        label(state, message, UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 34), 13, T.dim, false)
        return state
    end

    local function makeKeyPage(name: string, description: string, games: { string }, tier: string, expectedKeyType: string)
        local scroll = makePage(name)
        addPageTitle(scroll, name, description)

        local accessCard = makeCard(scroll, 142)
        accessCard.Name = "KeyAccess"
        accessCard.LayoutOrder = 2
        label(accessCard, "License key", UDim2.fromOffset(16, 13), UDim2.new(1, -32, 0, 20), 16, T.text, true)
        label(accessCard, "Enter the key assigned to your account.", UDim2.fromOffset(16, 39), UDim2.new(1, -32, 0, 16), 13, T.dim, false)

        local keyBox = Instance.new("TextBox")
        keyBox.Name = "KeyInput"
        keyBox.BackgroundColor3 = T.bg
        keyBox.BorderSizePixel = 0
        keyBox.ClearTextOnFocus = false
        keyBox.PlaceholderColor3 = T.muted
        keyBox.PlaceholderText = "Paste your key here"
        keyBox.Position = UDim2.fromOffset(16, 66)
        keyBox.Size = UDim2.new(1, -142, 0, 40)
        keyBox.Font = Enum.Font.Gotham
        keyBox.TextSize = 14
        keyBox.TextColor3 = T.text
        keyBox.TextXAlignment = Enum.TextXAlignment.Left
        keyBox.Text = ""
        keyBox.ZIndex = 10
        keyBox.Parent = accessCard
        corner(keyBox, UDim.new(0, 9))
        local inputStroke = stroke(keyBox, T.border, 1, 0.55)
        pad(keyBox, 13, 0, 13, 0)
        keyBox.Focused:Connect(function()
            tween(inputStroke, { Color = T.secondary, Transparency = 0.08 }, 0.12)
        end)
        keyBox.FocusLost:Connect(function()
            tween(inputStroke, { Color = T.border, Transparency = 0.55 }, 0.12)
        end)

        local verifyButton = Instance.new("TextButton")
        verifyButton.Name = "VerifyKey"
        verifyButton.BackgroundColor3 = T.primary
        verifyButton.BorderSizePixel = 0
        verifyButton.Position = UDim2.new(1, -110, 0, 66)
        verifyButton.Size = UDim2.fromOffset(94, 40)
        verifyButton.AutoButtonColor = false
        verifyButton.Font = Enum.Font.GothamBold
        verifyButton.TextSize = 14
        verifyButton.TextColor3 = Color3.new(1, 1, 1)
        verifyButton.Text = "Verify key"
        verifyButton.ZIndex = 10
        verifyButton.Parent = accessCard
        corner(verifyButton, UDim.new(0, 9))
        local verifyStroke = stroke(verifyButton, T.borderLight, 1, 0.42)
        verifyButton.MouseEnter:Connect(function()
            if verifyButton.Active then tween(verifyButton, { BackgroundColor3 = T.secondary }, 0.12) end
        end)
        verifyButton.MouseLeave:Connect(function()
            if verifyButton.Active then tween(verifyButton, { BackgroundColor3 = T.primary }, 0.12) end
        end)

        local status = label(accessCard, "Enter a key to continue.", UDim2.fromOffset(16, 115), UDim2.new(1, -32, 0, 16), 13, T.muted, false)
        status.TextYAlignment = Enum.TextYAlignment.Center

        local lockedState = makeLockedState(scroll, "Premium content is locked", "Verify your key above to view supported games.")
        lockedState.LayoutOrder = 3
        local gameList = makeGameList(scroll, games, tier)
        gameList.LayoutOrder = 4

        local checking = false
        verifyButton.MouseButton1Click:Connect(function()
            if checking then return end
            local key = string.gsub(keyBox.Text, "^%s*(.-)%s*$", "%1")
            if key == "" then
                status.Text = "Enter a key before verifying."
                status.TextColor3 = T.error
                return
            end

            checking = true
            verifyButton.Active = false
            verifyButton.Text = "Checking..."
            tween(verifyButton, { BackgroundColor3 = T.primaryDark }, 0.12)
            status.Text = "Checking your key..."
            status.TextColor3 = T.dim

            task.spawn(function()
                local requestOk, allowed = pcall(verifyAccess, key, expectedKeyType)
                if not loaderGui.Parent then return end
                if requestOk and allowed then
                    lockedState.Visible = false
                    gameList.Visible = true
                    keyBox.TextEditable = false
                    verifyButton.Text = "Verified"
                    verifyButton.BackgroundColor3 = T.success
                    verifyStroke.Color = T.success
                    status.Text = "Access verified. Select a game below."
                    status.TextColor3 = T.success
                    toast("Access verified", "Your game list is ready.", true)
                    return
                end

                checking = false
                verifyButton.Active = true
                verifyButton.Text = "Verify key"
                verifyButton.BackgroundColor3 = T.primary
                status.Text = "Key could not be verified. Try again."
                status.TextColor3 = T.error
                toast("Verification failed", "Check the key and try again.", false)
            end)
        end)
    end

    local function makeFreePage()
        local scroll = makePage("Free")
        addPageTitle(scroll, "Free", "Confirm access to view Free games.")

        local accessCard = makeCard(scroll, 126)
        accessCard.Name = "FreeAccess"
        accessCard.LayoutOrder = 2
        label(accessCard, "Free access", UDim2.fromOffset(16, 15), UDim2.new(1, -32, 0, 20), 16, T.text, true)
        label(accessCard, "No key is required for Free games.", UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 16), 13, T.dim, false)

        local confirmButton = Instance.new("TextButton")
        confirmButton.Name = "ConfirmAccess"
        confirmButton.BackgroundColor3 = T.primary
        confirmButton.BorderSizePixel = 0
        confirmButton.Position = UDim2.fromOffset(16, 70)
        confirmButton.Size = UDim2.new(1, -32, 0, 40)
        confirmButton.AutoButtonColor = false
        confirmButton.Font = Enum.Font.GothamBold
        confirmButton.TextSize = 14
        confirmButton.TextColor3 = Color3.new(1, 1, 1)
        confirmButton.Text = "Confirm access"
        confirmButton.ZIndex = 10
        confirmButton.Parent = accessCard
        corner(confirmButton, UDim.new(0, 9))
        local confirmStroke = stroke(confirmButton, T.borderLight, 1, 0.42)
        confirmButton.MouseEnter:Connect(function()
            if confirmButton.Active then tween(confirmButton, { BackgroundColor3 = T.secondary }, 0.12) end
        end)
        confirmButton.MouseLeave:Connect(function()
            if confirmButton.Active then tween(confirmButton, { BackgroundColor3 = T.primary }, 0.12) end
        end)

        local lockedState = makeLockedState(scroll, "Free games are ready", "Confirm access above to view supported games.")
        lockedState.LayoutOrder = 3
        local gameList = makeGameList(scroll, GAMES_FREE, "Free")
        gameList.LayoutOrder = 4

        confirmButton.MouseButton1Click:Connect(function()
            if not confirmButton.Active then return end
            confirmButton.Active = false
            confirmButton.Text = "Access confirmed"
            confirmButton.BackgroundColor3 = T.success
            confirmStroke.Color = T.success
            lockedState.Visible = false
            gameList.Visible = true
            toast("Access confirmed", "Choose a Free game to continue.", true)
        end)
    end

    local function makeInfoPage()
        local scroll = makePage("Info")
        addPageTitle(scroll, "Info", "Choose an access option to continue.")

        local infoCard = makeCard(scroll, 104)
        infoCard.LayoutOrder = 2
        label(infoCard, "Animula Hub", UDim2.fromOffset(16, 15), UDim2.new(1, -32, 0, 20), 16, T.text, true)
        label(infoCard, "Select Premium, Freemium, or Free from the navigation panel.", UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 34), 13, T.dim, false)
    end

    makeKeyPage("Premium", "Verify your Premium key to unlock Premium games.", GAMES_PREMIUM, "Premium", "pk")
    makeKeyPage("Freemium", "Verify your Freemium key to unlock Freemium games.", GAMES_FREEMIUM, "Freemium", "fk")
    makeFreePage()
    makeInfoPage()

    makeTab("Premium", 1)
    makeTab("Freemium", 2)
    makeTab("Free", 3)
    makeTab("Info", 4)
    showTab("Premium")

    local dragging = false
    local dragStart: Vector3? = nil
    local windowStart: UDim2? = nil
    header.Active = true
    header.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if UserInputService:GetFocusedTextBox() then return end
        dragging = true
        dragStart = input.Position
        windowStart = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input: InputObject)
        if not dragging or not dragStart or not windowStart then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        local position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset + delta.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset + delta.Y
        )
        main.Position = position
        glowLayer.Position = position
    end)

    UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
        if processed or input.KeyCode ~= Enum.KeyCode.RightShift then return end
        local visible = not main.Visible
        main.Visible = visible
        glowLayer.Visible = visible
    end)
end
