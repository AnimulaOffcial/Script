-- Animula Roblox Executor — MainScript (entry point)
-- Loads the Animula Ocean UI from GitHub, builds the hub UI (Home + Settings),
-- then loads every game module from MenuScript/<tier>/Game/<Game>/<Game>Loader.lua

local UI_BASE     = _G.ANIMULA_UI_BASE     or "https://raw.githubusercontent.com/AnimulaOffcial/UI/main/Script/MainUI"
local SCRIPT_BASE = _G.ANIMULA_SCRIPT_BASE or "https://raw.githubusercontent.com/AnimulaOffcial/Script/main/Script/MainScript"

-- Genshin "Biru Furina" accent (matches Web ocean-accent #38bdf8)
local Accent = Color3.fromRGB(56, 189, 248)

-- Tell the UI loader where its Components live (UILoader appends /Components/<name>.lua)
_G.ANIMULA_SOURCE = UI_BASE

-- ---------------------------------------------------------------------------
-- Load UI library
-- ---------------------------------------------------------------------------
local ok, Animula = pcall(function()
    return loadstring(game:HttpGet(UI_BASE .. "/UILoader.lua"))()
end)
if not ok or not Animula then
    error("Animula UI failed to load: " .. tostring(Animula))
end

pcall(function() Animula._Theme.Accent = Accent end)
pcall(function() _G.ANIMULA_ACCENT = Accent end)

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
local Root      = Character and Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid  = c:FindFirstChildOfClass("Humanoid")
    Root      = c:FindFirstChild("HumanoidRootPart")
end)

local selectedPlayer = nil

-- ---------------------------------------------------------------------------
-- Toolkit — safe, universal, error-free helpers
-- ---------------------------------------------------------------------------
local Toolkit = {}
Toolkit._flySpeed = 60

local connections = {}
local function stopConn(name)
    if connections[name] then
        pcall(function() connections[name]:Disconnect() end)
        connections[name] = nil
    end
end

function Toolkit.SetWalkSpeed(v)
    pcall(function() if Humanoid then Humanoid.WalkSpeed = v end end)
end
function Toolkit.SetJumpPower(v)
    pcall(function() if Humanoid then Humanoid.JumpPower = v end end)
end
function Toolkit.SetHipHeight(v)
    pcall(function() if Humanoid then Humanoid.HipHeight = v end end)
end

function Toolkit.SetInfiniteJump(v)
    stopConn("infjump")
    if v then
        connections.infjump = UserInputService.JumpRequest:Connect(function()
            pcall(function() if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
        end)
    end
end

function Toolkit.SetNoclip(v)
    stopConn("noclip")
    if v then
        connections.noclip = RunService.Stepped:Connect(function()
            pcall(function()
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        end)
    end
end

local flyBV = nil
function Toolkit.SetFly(v)
    stopConn("fly")
    if v then
        pcall(function()
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Velocity = Vector3.new()
            if Root then flyBV.Parent = Root end
        end)
        connections.fly = RunService.RenderStepped:Connect(function()
            pcall(function()
                local cam = Workspace.CurrentCamera
                local dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                if dir.Magnitude > 0 then dir = dir.Unit * (Toolkit._flySpeed or 60) end
                if flyBV then flyBV.Velocity = dir end
            end)
        end)
    else
        pcall(function() if flyBV then flyBV:Destroy() flyBV = nil end end)
    end
end
function Toolkit.SetFlySpeed(v) Toolkit._flySpeed = v end

local espTable = {}
function Toolkit.SetESP(v)
    pcall(function()
        for _, b in ipairs(espTable) do pcall(function() b:Destroy() end) end
    end)
    espTable = {}
    if v then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("Head") then
                pcall(function()
                    local b = Instance.new("BillboardGui")
                    b.Name = "AnimulaESP"
                    b.Size = UDim2.new(0, 140, 0, 20)
                    b.Adornee = pl.Character.Head
                    b.AlwaysOnTop = true
                    local t = Instance.new("TextLabel")
                    t.Size = UDim2.new(1, 0, 1, 0)
                    t.BackgroundTransparency = 1
                    t.Text = pl.Name
                    t.TextColor3 = Accent
                    t.Parent = b
                    b.Parent = game:GetService("CoreGui")
                    table.insert(espTable, b)
                end)
            end
        end
    end
end

function Toolkit.SetClickTP(v)
    stopConn("clicktp")
    if v then
        connections.clicktp = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                pcall(function()
                    local mouse = LocalPlayer:GetMouse()
                    if Root and mouse.Hit then
                        Root.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 3, 0))
                    end
                end)
            end
        end)
    end
end

function Toolkit.SetSpin(v)
    stopConn("spin")
    if v then
        connections.spin = RunService.RenderStepped:Connect(function()
            pcall(function()
                if Root then Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(10), 0) end
            end)
        end)
    end
end

function Toolkit.SetFullBright(v)
    pcall(function()
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 1000
            Lighting.GlobalShadows = true
        end
    end)
end

function Toolkit.GetPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(t, p.Name) end
    end
    return t
end

function Toolkit.SetSelectedPlayer(name)
    selectedPlayer = name
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == name then selectedPlayer = p end
        end
    end)
end

function Toolkit.TeleportToPlayer()
    pcall(function()
        local target = selectedPlayer
        if type(target) == "string" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name == target then target = p end
            end
        end
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and Root then
            Root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

function Toolkit.CopyJob()
    pcall(function()
        if setclipboard then setclipboard(tostring(game.JobId)) end
        Animula:MakeNotification({ Name = "Copied", Content = "JobId: " .. tostring(game.JobId), Time = 2 })
    end)
end
function Toolkit.Rejoin()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end
function Toolkit.NewServer()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

-- ---------------------------------------------------------------------------
-- Hub UI (built by MainScript itself, Genshin-blue theme)
-- ---------------------------------------------------------------------------
local Window = Animula:MakeWindow({ Name = "Animula Hub", ConfigFolder = "AnimulaHub", SaveConfig = true })

local function BuildHome()
    local Tab = Window:MakeTab({ Name = "Home", Icon = "rbxassetid://4483345998" })
    Tab:AddSection({ Name = "Animula Hub" })
    Tab:AddParagraph("Welcome", "Pick your game from the Games tab. Free and Premium are the same set (biar adil).")
    Tab:AddButton({
        Name = "Copy PlaceId",
        Callback = function()
            pcall(function() if setclipboard then setclipboard(tostring(game.PlaceId)) end end)
            Animula:MakeNotification({ Name = "Copied", Content = "PlaceId: " .. tostring(game.PlaceId), Time = 2 })
        end,
    })
    Tab:AddParagraph("Current PlaceId", tostring(game.PlaceId))
end

local function BuildSettings()
    local Tab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345999" })
    Tab:AddSection({ Name = "Config" })
    Tab:AddButton({ Name = "Save Config", Callback = function() pcall(function() Animula:SaveConfig() end) end })
    Tab:AddButton({ Name = "Destroy UI", Callback = function() pcall(function() Animula:Destroy() end) end })
end

-- ---------------------------------------------------------------------------
-- Load game modules from MenuScript/<tier>/Game/<Game>/<Game>Loader.lua
-- (Free == Premium, loaded once per unique game name)
-- ---------------------------------------------------------------------------
local loadedNames = {}

local function LoadGames(tier)
    local listUrl = SCRIPT_BASE .. "/MenuScript/" .. tier .. "/CheckGameID.lua"
    local okList, listSrc = pcall(function() return game:HttpGet(listUrl) end)
    if not okList or not listSrc then return end

    local okRun, names = pcall(function() return loadstring(listSrc)() or {} end)
    if not okRun or type(names) ~= "table" then return end

    for _, gname in ipairs(names) do
        if not loadedNames[gname] then
            local gurl = SCRIPT_BASE .. "/MenuScript/" .. tier .. "/Game/" .. gname .. "/" .. gname .. "Loader.lua"
            local okG, gsrc = pcall(function() return game:HttpGet(gurl) end)
            if okG and gsrc then
                local okMod, mod = pcall(function() return loadstring(gsrc)() end)
                if okMod and type(mod) == "function" then
                    local okBuild = pcall(mod, Animula, Window, Toolkit)
                    if okBuild then loadedNames[gname] = true end
                end
            end
        end
    end
end

BuildHome()
BuildSettings()
LoadGames("Free")
LoadGames("Premium")
Animula:Init()
