--!strict
-- ANIMULA HUB v3 - standalone loader UI (premium edition)
-- 100% self-contained: TANPA require ke LoaderUI / ComponentsUI manapun.
-- execute: loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/Script/main/LoaderScript.lua"))()
-- tabs: Premium (supabase keys) / Free (confirm + game list) / Info

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- supabase (project animula)
local SUPABASE_URL = "https://eiykqbkfljqxwfqdffpo.supabase.co"
local SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpeWtxYmtmbGpxeHdmcWRmZnBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4Mzg0NDIsImV4cCI6MjEwMzQxNDQ0Mn0.54QPoPN3LdV4gEqjEZydpI-bd3JZ_G9RZwlJIlxz3v4"

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
	muted = Color3.fromRGB(112, 139, 184),
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

-- supabase via RPC (anti bobol: anon cuma bisa check/redeem)
local function checkKeyViaRpc(key: string): (boolean, string)
	if key == "" then return false, "key kosong" end
	if #key < 10 then return false, "key kosong" end
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
	if string.match(key, "^Animula%-(pk|fk)%-[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]") and #key >= 34 then
		return true, "valid (offline)"
	end
	return false, "gagal cek, cek internet / format key"
end

local function checkPremiumKey(key: string): (boolean, string)
	return checkKeyViaRpc(key)
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

local function loadGameScript(gameName: string, tier: string): (boolean, string)
	local base = "https://raw.githubusercontent.com/AnimulaOffcial/Script/main/MenuScript/" .. tier .. "/Game/" .. gameName .. "/" .. gameName .. "Loader.lua"
	local ok, result = pcall(function()
		if type(loadstring) ~= "function" then
			error("executor tidak mendukung loadstring")
		end
		local code = game:HttpGet(base)
		if type(code) ~= "string" or #code <= 10 then
			error("script game kosong atau tidak ditemukan")
		end
		local chunk, compileError = loadstring(code)
		if not chunk then error(compileError or "script game tidak valid") end
		chunk()
	end)
	if not ok then
		local message = tostring(result)
		warn("[Animula] gagal load " .. gameName .. ": " .. message)
		return false, message
	end
	return true, "loaded"
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
main.Size = UDim2.fromOffset(660, 455)
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

-- bubbles (6)
task.spawn(function()
	for i = 1, 6 do
		local sz = math.random(3, 6)
		local b = Instance.new("Frame")
		b.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
		b.BackgroundTransparency = 0.7
		b.Size = UDim2.fromOffset(sz, sz)
		b.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, 1, math.random(-10, 10))
		b.BorderSizePixel = 0
		b.ZIndex = 1
		b.Parent = main
		corner(b, UDim.new(1, 0))
		local st = Instance.new("UIStroke")
		st.Color = T.accent
		st.Thickness = 1
		st.Transparency = 0.6
		st.Parent = b
		local function float()
			if not b.Parent then return end
			local sx = math.random() * 0.8 + 0.1
			b.Position = UDim2.new(sx, 0, 1, 6)
			local ex = sx + (math.random() - 0.5) * 0.08
			local dur = math.random(5, 9)
			local tw = TweenService:Create(b, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
				Position = UDim2.new(ex, 0, 0, -6),
			})
			tw:Play()
			tw.Completed:Wait()
			if b.Parent then
				task.wait(math.random() * 1.2)
				float()
			end
		end
		task.delay(math.random() * 2.5, float)
	end
end)

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

-- accent bar 3 warna + shimmer
do
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = T.primary
	bar.Size = UDim2.new(1, 0, 0, 3)
	bar.BorderSizePixel = 0
	bar.ZIndex = 8
	bar.Parent = main
	corner(bar, UDim.new(0, 99))
	gradient3(bar, T.primary, T.secondary, T.gold, 0)
	local c = bar:FindFirstChildOfClass("UICorner") :: any
	if c then c.CornerRadius = UDim.new(0, 18) end
	shimmerLoop(bar, UDim.new(0, 99), 1.5)
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
titleBar.Size = UDim2.new(1, 0, 0, 56)
titleBar.Position = UDim2.fromOffset(0, 4)
titleBar.ZIndex = 9
titleBar.Parent = main

-- icon + glow pulse
local iconWrap = Instance.new("Frame")
iconWrap.BackgroundColor3 = T.primary
iconWrap.Size = UDim2.fromOffset(38, 38)
iconWrap.Position = UDim2.fromOffset(14, 9)
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
iconLbl.TextSize = 19
iconLbl.TextColor3 = Color3.new(1, 1, 1)
iconLbl.Text = "◈"
iconLbl.ZIndex = 11
iconLbl.Parent = iconWrap

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.fromOffset(60, 8)
titleLbl.Size = UDim2.new(1, -160, 0, 20)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 17
titleLbl.TextColor3 = T.text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
titleLbl.Text = "Animula Hub"
titleLbl.ZIndex = 10
titleLbl.Parent = titleBar

local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency = 1
subLbl.Position = UDim2.fromOffset(60, 30)
subLbl.Size = UDim2.new(1, -160, 0, 14)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 11
subLbl.TextColor3 = T.dim
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Text = "v3  •  Premium / Free / Info"
subLbl.ZIndex = 10
subLbl.Parent = titleBar

-- status pill kanan (ONLINE)
local pill = Instance.new("Frame")
pill.BackgroundColor3 = Color3.fromRGB(16, 42, 30)
pill.Size = UDim2.fromOffset(76, 24)
pill.Position = UDim2.new(1, -118, 0, 14)
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
pillTxt.TextSize = 10
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
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 12)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
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

-- tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.BackgroundColor3 = T.bg
tabBar.BackgroundTransparency = 0.18
tabBar.Size = UDim2.new(0, 150, 1, -78)
tabBar.Position = UDim2.fromOffset(10, 62)
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

local pages: { [string]: Frame } = {}
local tabBtns: { [string]: TextButton } = {}
local currentTab = "Premium"

local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, -180, 1, -74)
body.Position = UDim2.fromOffset(170, 62)
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
	a.TextSize = 12
	a.TextColor3 = if ok == false then T.error else T.text
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Text = title
	a.Parent = n
	local b = Instance.new("TextLabel")
	b.BackgroundTransparency = 1
	b.Position = UDim2.fromOffset(0, 17)
	b.Size = UDim2.new(1, 0, 0, 14)
	b.Font = Enum.Font.Gotham
	b.TextSize = 11
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
			BackgroundColor3 = if isActive then T.primary else T.surface2,
			TextColor3 = if isActive then Color3.new(1, 1, 1) else T.dim,
		}, 0.18)
		local st = b:FindFirstChildOfClass("UIStroke") :: UIStroke?
		if st then tween(st, { Color = if isActive then T.primary else T.border }, 0.18) end
		-- gradient hanya untuk tab aktif (hapus dari yang nonaktif biar warnanya benar)
		local g = b:FindFirstChildOfClass("UIGradient")
		if isActive and not g then
			gradient(b, T.primary, T.primaryDark, 90)
		elseif not isActive and g then
			g:Destroy()
		end
	end
end

-- tab buttons (premium default aktif)
for _, info in ipairs({
	{ key = "Premium", label = "◆ Premium" },
	{ key = "Free", label = "◇ Free" },
	{ key = "Info", label = "ⓘ Info" },
}) do
	local b = Instance.new("TextButton")
	b.Name = info.key
	b.BackgroundColor3 = if info.key == currentTab then T.primary else T.surface2
	b.Size = UDim2.new(1, 0, 0, 38)
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 12
	b.TextColor3 = if info.key == currentTab then Color3.new(1, 1, 1) else T.dim
	b.Text = info.label
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.ZIndex = 9
	b.Parent = tabBar
	corner(b, UDim.new(0, 9))
	local st = stroke(b, if info.key == currentTab then T.primary else T.border, 1, 0.45)
	tabBtns[info.key] = b
	ripple(b, Color3.new(1, 1, 1))
	if info.key == currentTab then gradient(b, T.primary, T.primaryDark, 90) end
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
	l.TextSize = 11
	l.TextColor3 = T.accent
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = string.upper(text)
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
	layout.CellSize = UDim2.fromOffset(141, 31)
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
		b.TextSize = 11
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
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.ZIndex = 6
	btn.Parent = parent
	corner(btn, UDim.new(0, 9))
	gradient(btn, T.primary, T.primaryDark, 90)
	stroke(btn, T.borderLight, 1, 0.55)
	ripple(btn, Color3.new(1, 1, 1))
	shimmerLoop(btn, UDim.new(0, 9), 2.2)
	btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Color3.fromRGB(96, 176, 255) }, 0.12) end)
	btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = T.primary }, 0.12) end)
	btn.MouseButton1Down:Connect(function() tween(btn, { Size = UDim2.new(1, -2, 0, 32) }, 0.07) end)
	btn.MouseButton1Up:Connect(function() tween(btn, { Size = UDim2.new(1, 0, 0, 34) }, 0.1, Enum.EasingStyle.Back) end)
	return btn
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
	sectionTitle(sc, "Premium Access")

	local card = Instance.new("Frame")
	card.BackgroundColor3 = T.surface2
	card.Size = UDim2.new(1, 0, 0, 96)
	card.BorderSizePixel = 0
	card.ZIndex = 6
	card.Parent = sc
	corner(card, UDim.new(0, 12))
	local cardStroke = stroke(card, T.border, 1, 0.3)
	pad(card, 12, 10, 12, 10)
	hoverGlow(card, T.surface2, cardStroke, T.border, T.borderLight)

	local l1 = Instance.new("TextLabel")
	l1.BackgroundTransparency = 1
	l1.Size = UDim2.new(1, 0, 0, 15)
	l1.Font = Enum.Font.GothamBold
	l1.TextSize = 13
	l1.TextColor3 = T.text
	l1.TextXAlignment = Enum.TextXAlignment.Left
	l1.Text = "Premium Keys"
	l1.Parent = card

	local l2 = Instance.new("TextLabel")
	l2.BackgroundTransparency = 1
	l2.Position = UDim2.fromOffset(0, 17)
	l2.Size = UDim2.new(1, 0, 0, 12)
	l2.Font = Enum.Font.Gotham
	l2.TextSize = 10
	l2.TextColor3 = T.muted
	l2.TextXAlignment = Enum.TextXAlignment.Left
	l2.Text = "masukin key, otomatis cek ke supabase + bind roblox id"
	l2.Parent = card

	local keyBox = Instance.new("TextBox")
	keyBox.BackgroundColor3 = T.bg
	keyBox.Size = UDim2.new(1, -92, 0, 30)
	keyBox.Position = UDim2.fromOffset(0, 36)
	keyBox.Font = Enum.Font.Gotham
	keyBox.TextSize = 12
	keyBox.TextColor3 = T.text
	keyBox.PlaceholderText = "Animula-pk-XXXXX / Animula-fk-XXXXX"
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
	checkBtn.Size = UDim2.fromOffset(84, 30)
	checkBtn.Position = UDim2.new(1, -84, 0, 36)
	checkBtn.Font = Enum.Font.GothamBold
	checkBtn.TextSize = 11
	checkBtn.TextColor3 = Color3.new(1, 1, 1)
	checkBtn.Text = "Check ✓"
	checkBtn.AutoButtonColor = false
	checkBtn.BorderSizePixel = 0
	checkBtn.ZIndex = 7
	checkBtn.Parent = card
	corner(checkBtn, UDim.new(0, 8))
	gradient(checkBtn, T.primary, T.primaryDark, 90)
	ripple(checkBtn, Color3.new(1, 1, 1))
	checkBtn.MouseEnter:Connect(function() tween(checkBtn, { BackgroundColor3 = Color3.fromRGB(96, 176, 255) }, 0.12) end)
	checkBtn.MouseLeave:Connect(function()
		if not premiumState.unlocked then tween(checkBtn, { BackgroundColor3 = T.primary }, 0.12) end
	end)
	premiumState.checkBtn = checkBtn

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.fromOffset(0, 70)
	hint.Size = UDim2.new(1, 0, 0, 12)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 10
	hint.TextColor3 = T.muted
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = "dapatkan key di web /generetekey (fk) atau beli (pk)"
	hint.Parent = card

	local statusLbl = Instance.new("TextLabel")
	statusLbl.BackgroundTransparency = 1
	statusLbl.Size = UDim2.new(1, 0, 0, 15)
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 11
	statusLbl.TextColor3 = T.dim
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Text = ""
	statusLbl.Parent = sc
	premiumState.status = statusLbl

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

	local loadBtn = primaryButton(gameWrap, "Load Premium Script  ▶")
	loadBtn.LayoutOrder = 99

	checkBtn.MouseButton1Click:Connect(function()
		local key = keyBox.Text
		statusLbl.Text = "⏳ ngecek..."
		statusLbl.TextColor3 = T.dim
		tween(keyStroke, { Color = T.primary }, 0.15)
		task.wait(0.08)
		local okR, msgR = redeemKey(key)
		if okR then
			premiumState.unlocked = true
			statusLbl.Text = "✓ " .. msgR
			statusLbl.TextColor3 = T.success
			gameWrap.Visible = true
			tween(checkBtn, { BackgroundColor3 = T.success }, 0.2)
			checkBtn.Text = "Valid ✓"
			notify("Keys valid", "premium kebuka, pilih game lalu load", true)
		else
			local ok, msg = checkPremiumKey(key)
			if ok and string.find(msgR, "already redeemed") then
				premiumState.unlocked = true
				statusLbl.Text = "✓ " .. msg .. " (welcome back)"
				statusLbl.TextColor3 = T.success
				gameWrap.Visible = true
				checkBtn.Text = "Valid ✓"
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
	sectionTitle(sc, "Free Access")

	local card = Instance.new("Frame")
	card.BackgroundColor3 = T.surface2
	card.Size = UDim2.new(1, 0, 0, 58)
	card.BorderSizePixel = 0
	card.ZIndex = 6
	card.Parent = sc
	corner(card, UDim.new(0, 12))
	local cardStroke = stroke(card, T.border, 1, 0.3)
	pad(card, 12, 9, 12, 9)
	hoverGlow(card, T.surface2, cardStroke, T.border, T.borderLight)

	local t1 = Instance.new("TextLabel")
	t1.BackgroundTransparency = 1
	t1.Size = UDim2.new(1, -96, 0, 15)
	t1.Font = Enum.Font.GothamBold
	t1.TextSize = 13
	t1.TextColor3 = T.text
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.Text = "Free Hub"
	t1.Parent = card

	local t2 = Instance.new("TextLabel")
	t2.BackgroundTransparency = 1
	t2.Position = UDim2.fromOffset(0, 17)
	t2.Size = UDim2.new(1, -96, 0, 12)
	t2.Font = Enum.Font.Gotham
	t2.TextSize = 10
	t2.TextColor3 = T.muted
	t2.TextXAlignment = Enum.TextXAlignment.Left
	t2.Text = "langsung confirm, gak perlu keys"
	t2.Parent = card

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.BackgroundColor3 = T.surface
	confirmBtn.Size = UDim2.fromOffset(86, 30)
	confirmBtn.Position = UDim2.new(1, -86, 0.5, -15)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 11
	confirmBtn.TextColor3 = T.dim
	confirmBtn.Text = "Confirm"
	confirmBtn.AutoButtonColor = false
	confirmBtn.BorderSizePixel = 0
	confirmBtn.ZIndex = 7
	confirmBtn.Parent = card
	corner(confirmBtn, UDim.new(0, 8))
	local confirmStroke = stroke(confirmBtn, T.border, 1, 0.4)
	ripple(confirmBtn, Color3.new(1, 1, 1))

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

	local loadFree = primaryButton(gameWrapFree, "Load Free Script  ▶")
	loadFree.LayoutOrder = 99

	confirmBtn.MouseButton1Click:Connect(function()
		freeState.confirmed = not freeState.confirmed
		local on = freeState.confirmed
		tween(confirmBtn, {
			BackgroundColor3 = if on then T.success else T.surface,
			TextColor3 = if on then Color3.new(1, 1, 1) else T.dim,
		}, 0.15)
		tween(confirmStroke, { Color = if on then T.success else T.border }, 0.15)
		confirmBtn.Text = if on then "Confirmed ✓" else "Confirm"
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
		c.Size = UDim2.new(1, 0, 0, 56)
		c.AutomaticSize = Enum.AutomaticSize.Y
		c.BorderSizePixel = 0
		c.ZIndex = 6
		c.Parent = sc
		corner(c, UDim.new(0, 12))
		local st = stroke(c, T.border, 1, 0.32)
		pad(c, 12, 9, 12, 9)
		hoverGlow(c, T.surface2, st, T.border, T.borderLight)
		local a = Instance.new("TextLabel")
		a.BackgroundTransparency = 1
		a.Size = UDim2.new(1, 0, 0, 15)
		a.Font = Enum.Font.GothamBold
		a.TextSize = 12
		a.TextColor3 = T.text
		a.TextXAlignment = Enum.TextXAlignment.Left
		a.Text = title
		a.Parent = c
		local b = Instance.new("TextLabel")
		b.BackgroundTransparency = 1
		b.Position = UDim2.fromOffset(0, 17)
		b.Size = UDim2.new(1, 0, 0, 14)
		b.AutomaticSize = Enum.AutomaticSize.Y
		b.Font = Enum.Font.Gotham
		b.TextSize = 11
		b.TextColor3 = T.dim
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.TextWrapped = true
		b.Text = desc
		b.Parent = c
		return c
	end

	infoCard("Animula Hub v3", "Premium = keys via Supabase (bind Roblox ID). Free = confirm lalu load.")
	infoCard("Execute Loader", 'loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/Script/main/LoaderScript.lua"))()')
	infoCard("Support", "DM di discord kalau keys premium bermasalah.")

	local discordBtn = primaryButton(sc, "Copy Discord Invite")
	discordBtn.MouseButton1Click:Connect(function()
		if setclipboard then setclipboard("https://discord.gg/animula") end
		notify("Copied", "discord invite ke clipboard", true)
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
